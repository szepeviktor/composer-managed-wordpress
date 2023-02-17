### Remove default content

```bash
wp post delete $(wp post list --name="$(wp eval 'echo sanitize_title( _x( "hello-world", "Default post slug" ) );')" --posts_per_page=1 --format=ids)
wp post delete $(wp post list --post_type=page --name="$(wp eval 'echo __( "sample-page" );')" --posts_per_page=1 --format=ids)
wp comment delete 1
wp option update blogdescription "Install and manage WordPress with Composer"
wp plugin uninstall akismet
wp plugin uninstall hello-dolly
wp theme delete twentytwentyone
wp theme delete twentytwentytwo
wp theme delete twentytwentythree
```

### Custom index for posts table

```sql
ALTER TABLE `wp_posts` ADD fulltext(`post_title`);
```

### WP-Cron

1. Disable web-based cron as it runs on PHP-FPM
1. Run WP-Cron from a Linux cron job
   https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/wp-install/wp-cron-cli.sh
1. WordPress has no built-in queues (immediate background jobs)

### Settings

- General Settings
- Writing Settings
- Reading Settings
- Media Settings
- Permalink Settings
- WP Mail From

### Continuous delivery (CD)

1. Developer starts GitHub Actions workflow
1. GitHub Actions connects to the server through SSH starting `deploy-receiver.sh`
1. On the server `deploy-receiver.sh` checks out git repository and updates dependencies with Composer

:bulb: There are many other steps. Please see and edit [`deploy-receiver.sh`](/deploy-receiver.sh).

- Install Debian packages: `grepcidr jq libpng-dev php7.4-fpm`
- Install [WP-CLI](https://github.com/szepeviktor/debian-server-tools/blob/master/debian-setup/packages/php-wpcli)
- Install [cachetool](https://github.com/szepeviktor/debian-server-tools/blob/master/debian-setup/packages/php-cachetool)
- Configure cachetool: `editor ~/.cachetool.yml`
  ```yaml
  adapter: "fastcgi"
  fastcgi: "/run/php/php7.4-fpm-$USER.sock"
  temp_dir: "/home/$USER/website/tmp"
  ```
- Install `php-parallel-lint/php-parallel-lint` globally (on user level)
  ```bash
  composer global require --update-no-dev php-parallel-lint/php-parallel-lint
  ```
- Generate an SSH deploy key: `ssh-keygen -t ed25519`
- Add the public part to GitHub Actions Deploy keys (no write access)
- Clone the repository in `/home/$USER/website/code`: `git clone https://github.com/org-name/repository-name.git .`
- Connect manually: `git fetch origin`
- Add the public part to user: `editor ~/.ssh/authorized_keys`
  ```
  restrict,command="/home/$USER/website/deploy-receiver.sh" ssh-ed25519 AAAA...
  ```
- Set up GitHub Actions secrets for each environment, match git branch names to environments, e.g. staging, production
  ```ini
  PROD_CD_SSH_USER_AT_HOST
  PROD_CD_SSH_KEY_B64
  PROD_CD_SSH_KNOWN_HOSTS_B64

  STAGING_CD_SSH_USER_AT_HOST
  STAGING_CD_SSH_KEY_B64
  STAGING_CD_SSH_KNOWN_HOSTS_B64
  ```
  This is how to get values.
  ```bash
  # *_CD_SSH_USER_AT_HOST
  echo $(id --user --name)@$(hostname --fqdn)
  # *_CD_SSH_KEY_B64
  cat ~/.ssh/id_ed25519 | base64 -w 0; echo
  # *_CD_SSH_KNOWN_HOSTS_B64
  ssh-keyscan -p $PORT $HOST | base64 -w 0; echo
  ```
- Create `/home/$USER/website/deploy-data` on the server
  ```ini
  PROJECT_PATH=org-name/repository-name
  COMMIT_REF_NAME=production
  GIT_WORK_TREE=/home/$USER/website/code
  ```
- Optionally set up Composer authentication: `composer config --global github-oauth.github.com $PERSONAL-ACCESS-TOKEN`
- Start your first deployment!
