#!/bin/bash
#
# Automatic deployment.
#
# VERSION       :0.3.0
# DOCS          :https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/Continuous-integration-Continuous-delivery.md
# DEPENDS       :apt-get install grepcidr jq libpng-dev php7.4-fpm
# DEPENDS2      :php-cachetool php-wpcli
# SECRET        :*_CD_SSH_KNOWN_HOSTS_B64
# SECRET        :*_CD_SSH_KEY_B64
# SECRET        :*_CD_SSH_USER_AT_HOST
# CONFIG-VAR    :PROJECT_PATH
# CONFIG-VAR    :COMMIT_REF_NAME
# CONFIG-VAR    :GIT_WORK_TREE

DEPLOY_CONFIG_NAME="deploy-data"

Check_gihub_ci_ip()
{
    local IP="$1"

    echo "Connecting IP check: ${IP}"

    NETWORKS="$(wget -q -O- https://api.github.com/meta | jq -r '.actions[]')"

    if ! grepcidr "${NETWORKS}" <<< "${IP}"; then
        echo "Unknown IP tried to deploy: https://bgp.he.net/ip/${IP}" \
            | s-nail -s "[deploy] Check_gihub_ci_ip() error" admin@szepe.net
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

    if [ "$RET" -ne 0 ]; then
        echo "COMMAND WITH ERROR: ${BASH_CMD}" 1>&2
    fi

    exit "$RET"
}

Get_config()
{
    # Configuration file containing PROJECT_PATH, COMMIT_REF_NAME, GIT_WORK_TREE
    DEPLOY_CONFIG_PATH="$(dirname "$0")/${DEPLOY_CONFIG_NAME}"
    if [ ! -r "$DEPLOY_CONFIG_PATH" ]; then
        echo "[ERROR] Unconfigured" 1>&2
        exit 1
    fi

    # Global
    # shellcheck disable=SC1090
    source "$DEPLOY_CONFIG_PATH"
}

Check_config()
{
    # Check deploy configuration
    if ! Check_name "$PROJECT_PATH"; then
        echo "[ERROR] Project path not configured correctly: (${PROJECT_PATH})" 1>&2
        exit 10
    fi

    if ! Check_name "$COMMIT_REF_NAME"; then
        echo "[ERROR] Branch name not configured correctly: (${COMMIT_REF_NAME})" 1>&2
        exit 11
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
    echo "Received:                 '${CI_PROJECT_PATH}#${CI_COMMIT_REF_NAME}@${CI_COMMIT_SHA}'"

    # Check commit data
    if [ "${CI_PROJECT_PATH}/${CI_COMMIT_REF_NAME}" != "${PROJECT_PATH}/${COMMIT_REF_NAME}" ]; then
        echo "[ERROR] Invalid repository or branch: (${CI_PROJECT_PATH}/${CI_COMMIT_REF_NAME})" 1>&2
        exit 20
    fi
    echo "Project path + branch OK: ${CI_PROJECT_PATH}#${CI_COMMIT_REF_NAME}"

    if ! Check_hash "$CI_COMMIT_SHA"; then
        echo "[ERROR] Invalid commit hash: (${CI_COMMIT_SHA})" 1>&2
        exit 21
    fi
    echo "Commit hash OK:           ${CI_COMMIT_SHA}"

    echo "Database wipe:            ${CI_DB_WIPE}"

    echo "Starting deployment ..."
}

Deploy()
{
    local COMMIT

    # Locked for singleton execution
    {
        flock 9

        COMMIT="$CI_COMMIT_SHA"
        if ! Check_hash "$COMMIT"; then
            echo "[ERROR] Invalid commit hash: (${COMMIT})" 1>&2
            exit 30
        fi

        # Check write permission
        if [ ! -w "$GIT_WORK_TREE" ]; then
            echo "[ERROR] Cannot write to work tree" 1>&2
            stat "$GIT_WORK_TREE" 1>&2
            exit 31
        fi

        # Check .env file
        if [ ! -r "${GIT_WORK_TREE}/.env" ]; then
            echo "[ERROR] Cannot read .env file" 1>&2
            stat "${GIT_WORK_TREE}/.env" 1>&2
            exit 32
        fi

        cd "$GIT_WORK_TREE"

        echo "Remotes:"
        git remote -v
        echo "Branches:"
        git branch -r
        git branch

        echo "Fetching origin ..."
        git remote show origin >/dev/null
        timeout 30 git fetch --prune origin

        ## test "$(git remote get-url origin)" == "$GIT_URL"
        ## test "$(git rev-parse --abbrev-ref HEAD)" == master

        # Down!
        if [ -f "$(wp cli param-dump --with-values | jq -r '."path"."current" + "/wp-includes/version.php"')" ]; then
            # Check root pages
            echo test "$(wp post list --format=count --post_type=page --name=esztetika)" -eq 1
            echo test "$(wp post list --format=count --post_type=page --name=plasztika)" -eq 1
            echo test "$(wp post list --format=count --post_type=page --name=gyogyaszat)" -eq 1
            wp maintenance-mode activate
            # Clear caches
            wp cache flush
        fi

        echo "Checking out work tree..."
        git -c advice.detachedHead=false checkout --force "$COMMIT"

        # PHP syntax check
        "$(composer global config --absolute vendor-dir)/bin/parallel-lint" --exclude vendor .

        # Check composer.json
        composer validate --strict

        # Update everything
        timeout 60 composer update --no-progress --no-dev
        # Update only the theme
#        timeout 60 composer update --no-progress --no-dev org-name/repository-name

        # Verify WordPress installation
        wp core verify-checksums
        wp plugin verify-checksums --all --strict

        # Check required core version of plugins
        wp eval 'foreach(get_option("active_plugins") as $p)if(version_compare(get_plugin_data(WP_PLUGIN_DIR."/".$p)["RequiresWP"],get_bloginfo("version"),">")){error_log("Incompatible plugin version:".$p);exit(10);}'

        # Display theme version
        echo -n "Theme package version: "
        composer show --format=json org-name/repository-name | jq -r '."versions"[0]'
        echo -n "Theme version: "
        wp eval 'var_dump(\Company\ThemeName\Theme::VERSION);'

        # Reset OPcache
        cachetool opcache:reset

        # Build front-end assets
        npm --prefix="$(wp eval 'echo dirname(get_template_directory());')" ci --omit=dev
        npm --prefix="$(wp eval 'echo dirname(get_template_directory());')" run prod

        # UP!
        if [ -z "$(find . -path "*/wp-includes/version.php" -cmin 10)" ]; then
            wp maintenance-mode deactivate
        fi

        # Email notification
        echo "All is well: https://github.com/${CI_PROJECT_PATH}/commit/${COMMIT}" \
            | mail -s "[${CI_PROJECT_PATH}] Deployment complete" admin@szepe.net

        wp eval 'echo admin_url(), PHP_EOL;'
        echo "OK."
    } 9< "$0"
}

set -e

trap 'Onexit "$?" "$BASH_COMMAND"' EXIT HUP INT QUIT PIPE TERM

logger -t "Deploy-receiver" "Started from ${SSH_CLIENT%% *}"
Check_gihub_ci_ip "${SSH_CLIENT%% *}"

Get_config
Check_config

Receive_commit
Deploy

exit 0
