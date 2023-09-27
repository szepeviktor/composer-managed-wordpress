#!/bin/bash
#
# Automatic deployment.
#
# VERSION       :0.6.0
# DOCS          :https://github.com/szepeviktor/composer-managed-wordpress
# DEPENDS       :apt-get install grepcidr jq libpng-dev php7.4-fpm
# DEPENDS2      :php-wpcli php-cachetool
# SECRET        :CD_SSH_KNOWN_HOSTS_B64
# SECRET        :CD_SSH_KEY_B64
# SECRET        :CD_SSH_USER_AT_HOST
# CONFIG-VAR    :PROJECT_PATH
# CONFIG-VAR    :GIT_WORK_TREE
# shellcheck disable=SC2317

DEPLOY_CONFIG_NAME="deploy-data"

Check_github_ci_ip()
{
    local IP="$1"

    echo "Connecting IP check: ${IP}"

    NETWORKS="$(wget -q -O- https://api.github.com/meta | jq -r '."actions"[]')"

    if ! grepcidr "${NETWORKS}" <<<"${IP}"; then
        echo "Unknown IP tried to deploy: https://bgp.he.net/ip/${IP}" \
            | s-nail -s "[deploy] Check_github_ci_ip() error" admin@szepe.net
        echo "Unknown IP tried to deploy: ${IP}" 1>&2
        exit 1
    fi
}

Check_name()
{
    [[ "$1" =~ ^[0-9a-zA-Z_/-]+$ ]]
}

Check_hash()
{
    [[ "$1" =~ ^[0-9a-f]{40}$ ]]
}

Onexit()
{
    local -i RET="$1"
    local BASH_CMD="$2"

    set +e

    if [ "${RET}" -ne 0 ]; then
        echo "COMMAND WITH ERROR: ${BASH_CMD}" 1>&2
    fi

    exit "${RET}"
}

Get_config()
{
    # Configuration file containing PROJECT_PATH, GIT_WORK_TREE
    DEPLOY_CONFIG_PATH="$(dirname "$0")/${DEPLOY_CONFIG_NAME}"
    if [ ! -r "${DEPLOY_CONFIG_PATH}" ]; then
        echo "[ERROR] Unconfigured" 1>&2
        exit 1
    fi

    # Global
    # shellcheck disable=SC1090
    source "${DEPLOY_CONFIG_PATH}"
}

Check_config()
{
    # Check deploy configuration
    if ! Check_name "${PROJECT_PATH}"; then
        echo "[ERROR] Project path not configured correctly: (${PROJECT_PATH})" 1>&2
        exit 10
    fi

    if [ ! -e "${GIT_WORK_TREE}/.git" ]; then
        echo "[ERROR] Git work tree is not available: (${GIT_WORK_TREE})" 1>&2
        exit 12
    fi
}

Receive_commit()
{
    # Globals
    read -r CI_PROJECT_PATH CI_COMMIT_REF_NAME CI_COMMIT_SHA CI_DB_WIPE
    printf '%-27s"%s#%s@%s"\n' "Received:" "${CI_PROJECT_PATH}" "${CI_COMMIT_REF_NAME}" "${CI_COMMIT_SHA}"

    # Check commit data
    if [ "${CI_PROJECT_PATH}" != "${PROJECT_PATH}" ]; then
        echo "[ERROR] Invalid repository: (${CI_PROJECT_PATH})" 1>&2
        exit 20
    fi
    printf '%-28s%s#%s\n' "Project path + branch OK:" "${CI_PROJECT_PATH}" "${CI_COMMIT_REF_NAME}"

    if ! Check_hash "${CI_COMMIT_SHA}"; then
        echo "[ERROR] Invalid commit hash: (${CI_COMMIT_SHA})" 1>&2
        exit 21
    fi
    printf '%-28s%s\n' "Commit hash OK:" "${CI_COMMIT_SHA}"

    printf '%-28s%s\n' "Database wipe:" "${CI_DB_WIPE}"
}

Deploy()
{
    echo "Starting deployment ..."

    # Locked for singleton execution
    {
        flock 9

        if ! Check_hash "${CI_COMMIT_SHA}"; then
            echo "[ERROR] Invalid commit hash: (${CI_COMMIT_SHA})" 1>&2
            exit 30
        fi

        # Check write permission
        if [ ! -w "${GIT_WORK_TREE}" ]; then
            echo "[ERROR] Cannot write to work tree" 1>&2
            stat "${GIT_WORK_TREE}" 1>&2
            exit 31
        fi

        # Check .env file
        if [ ! -r "${GIT_WORK_TREE}/.env" ]; then
            echo "[ERROR] Cannot read .env file" 1>&2
            stat "${GIT_WORK_TREE}/.env" 1>&2
            exit 32
        fi

        cd "${GIT_WORK_TREE}"

        echo "Remotes:"
        git remote -v
        echo "Branches:"
        git branch -r
        git branch

        echo "Fetching origin ..."
        git remote show origin >/dev/null
        timeout 30 git fetch --prune origin

        ## test "$(git remote get-url origin)" == "${GIT_URL}"
        ## test "$(git rev-parse --abbrev-ref HEAD)" == branch-name

        # Down!
        if [ -f "$(wp cli param-dump --with-values | jq -r '."path"."current" + "/wp-includes/version.php"')" ]; then
            # Check special pages
            test "$(wp post list --format=count --post_type=page --name=esztetika)" -eq 1
            test "$(wp post list --format=count --post_type=page --name=plasztika)" -eq 1
            test "$(wp post list --format=count --post_type=page --name=gyogyaszat)" -eq 1
            wp maintenance-mode activate
            # Clear caches
            wp cache flush
        fi

        echo "Checking out work tree..."
        git -c advice.detachedHead=false checkout --force "${CI_COMMIT_SHA}"

        # Check Composer configuration - works only with composer.lock file committed
        composer validate --no-interaction --strict
        #composer validate --no-interaction --strict --no-check-lock

        # Update everything
        #timeout 60 composer update --no-interaction --no-progress --no-dev
        # Update only the theme
        timeout 60 composer update --no-interaction --no-progress --no-dev org-name/repository-name

        # PHP syntax check
        composer global exec --no-interaction -- parallel-lint --exclude vendor .

        # Verify WordPress installation
        wp core verify-checksums
        wp plugin verify-checksums --all --strict

        # Check required core version of plugins
        # shellcheck disable=SC2016
        wp eval '
            foreach (get_option("active_plugins") as $plugin) {
                if (
                    version_compare(
                        get_plugin_data(WP_PLUGIN_DIR."/".$plugin)["RequiresWP"],
                        get_bloginfo("version"),
                        ">"
                    )
                ) {
                    error_log("Incompatible plugin version:".$plugin);
                    exit(33);
                }
            }
            '

        # Update database
        wp core update-db

        # Update translations
        wp language core update
        wp language plugin update --all

        # Check object cache type
        test "$(wp cache type)" == Redis

        # Verify critical options
        test "$(wp option get users_can_register)" == 0
        test "$(wp option get admin_email)" == admin@szepe.net
        test "$(wp option get blog_charset)" == UTF-8

        # Custom checks
        #test "$(wp eval 'echo perflab_get_module_settings()["images/webp-uploads"]["enabled"];')" == 1

        # Search for ACF Options Page options with default name prefix
        test -z "$(wp option list --search="options_*" --field=option_name)"
        test -z "$(wp option list --search="_options_*" --field=option_name)"

        # Display theme version
        echo -n "Theme package version: "
        composer show --no-interaction --format=json org-name/repository-name | jq -r '."versions"[0]'
        echo -n "Theme version: "
        wp eval 'var_dump(wp_get_theme()->get("Version"));'
        echo -n "Theme version constant: "
        wp eval 'var_dump(\Company\ThemeName\Theme::VERSION);'

        # Trigger theme setup
        #wp eval '$theme = wp_get_theme("our-theme"); do_action("after_switch_theme", $theme->get("Name"), $theme);'
        # Fire "deploy" hook
        wp eval 'do_action("deploy");'

        # Reset OPcache
        cachetool opcache:reset

        # Build theme front-end assets - with theme/ subdirectory
        npm --prefix="$(wp eval 'echo dirname(get_template_directory());')" ci --omit=dev
        npm --prefix="$(wp eval 'echo dirname(get_template_directory());')" run production

        # Remove references to source maps
        grep -rlZ -- '^//# sourceMappingURL=' "$(wp eval 'echo dirname(get_template_directory());')" \
            | xargs -0 -r -L1 -- sed -i -e '/^\/\/# sourceMappingURL=\S\+\.map$/d'

        # UP!
        # .maintenance file is removed during WordPress core update
        if [ -z "$(find "$(wp cli param-dump --with-values | jq -r '."path"."current" + "/wp-includes/version.php"')" -cmin -10)" ]; then
            wp maintenance-mode deactivate
        fi

        wp eval 'echo admin_url(), PHP_EOL;'
    } 9<"$0"
}

set -e

trap 'Onexit "$?" "${BASH_COMMAND}"' EXIT HUP INT QUIT PIPE TERM

logger -t "Deploy-receiver" "Started from ${SSH_CLIENT%% *}"
Check_github_ci_ip "${SSH_CLIENT%% *}"

Get_config
Check_config

Receive_commit
Deploy

# Send email notification
echo "All is well: https://github.com/${CI_PROJECT_PATH}/commit/${CI_COMMIT_SHA}" \
    | mail -s "[${CI_PROJECT_PATH}] Deployment complete" admin@szepe.net

echo "OK."
exit 0
