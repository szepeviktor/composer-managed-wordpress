# Composer managed WordPress

You may learn how I install WordPress.
Almost everything will come from Composer packages, the rest is under version control (git).

Thus the repository of a WordPress installation should barely contain files.

### Directory structure

Most of these files are excluded from this repository as they are installed by Composer!

- `/`: root directory with configuration files and documents
- `vendor/`: dependencies (packages)
- `public/`: webserver's document root with `index.php` and `wp-config.php`
- `public/$PROJECT_NAME/`: WordPress core
- `public/wp-content/`: `wp-content` directory

### Package types

- Themes from WordPress.org's theme directory through wpackagist
- Your custom theme should be developed as a separate package in a repository of its own
- Plugins from WordPress.org's plugin directory through wpackagist
- Your custom plugins should be developed as separate packages
- Purchased plugins can be installed by `ffraenz/private-composer-installer`
- Must-use plugins and dropins can be installed by `koodimonni/composer-dropin-installer`

All other files - except `wp-config.php` - should be kept under version control.

### Usage

1. Run WordPress core, plugins and theme on PHP 7.4 (as of 2022)
1. Set `WP_ENVIRONMENT_TYPE` environment variable
   (in [PHP-FPM configuration](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/phpfpm-pools/Skeleton-pool.conf) or in `wp-config.php`)
1. Change the directory name "project" in: `.gitignore`, `composer.json`, `public/index.php`, `wp-cli.yml`
1. Customize `composer.json` and create documents
1. Create `.env` if you have purchased plugins
1. Set GitHub OAuth token if you develop a private theme or plugins
   `composer config github-oauth.github.com "$YOUR_GITHUB_TOKEN"`
1. Create [`public/wp-config.php`](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/wp-install/wp-config.php)
1. Issue `composer update --no-dev`
1. Administer your WordPress installation with [WP-CLI](https://make.wordpress.org/cli/handbook/guides/installing/)
