# Composer managed WordPress

You may learn how I install WordPress.
Almost everything will come from Composer packages, the rest is under version control (git).

Thus the repository of a WordPress installation should barely contain files.

## Support my work

Please consider sponsoring me monthly if you use my packages in an agency.

[![Sponsor](https://github.com/szepeviktor/.github/raw/master/.github/assets/github-like-sponsor-button.svg)](https://github.com/sponsors/szepeviktor)

## Directory structure

Most of these files are excluded from this repository as they are installed by Composer!

- `/`: root directory with configuration files and documents
- `vendor/`: dependencies (packages)
- `public/`: webserver's document [root](https://github.com/szepeviktor/RootFiles) with `index.php`, `wp-config.php`, `favicon.ico`
- `public/$PROJECT_NAME/`: WordPress core
- `public/wp-content/`: `wp-content` directory

```
vendor/
UPGRADE.md
composer.json
composer.lock
wp-cli.yml
public/─┬─index.php (modified)
        ├─wp-config.php
        ├─PROJECT_NAME/─┬─index.php
        │               ├─wp-load.php
        │               ├─wp-login.php
        │               ├─wp-admin/
        │               └─wp-includes/
        └─wp-content/
```

## Package types

- Themes from WordPress.org's theme directory through wpackagist
- Your [custom theme](https://github.com/timber/starter-theme/tree/2.x) should be developed as a separate package in a repository of its own
- Plugins from WordPress.org's plugin directory through wpackagist
- Your [custom plugins](https://github.com/szepeviktor/starter-plugin) should be developed as separate packages
- Purchased plugins can be installed by `ffraenz/private-composer-installer`
- Must-use plugins and dropins can be installed by `koodimonni/composer-dropin-installer`

All other files - except `public/wp-config.php` - should be kept under version control.

## Usage

1. Run WordPress core, plugins and theme on PHP 7.4 (as of 2023)
1. Change the directory name "project" in `.gitignore`, `composer.json`, `public/index.php`, `wp-cli.yml`
1. Customize `composer.json` and create documents
1. Create `.env` if you have purchased plugins
1. Add [MU plugins](https://github.com/szepeviktor/wordpress-website-lifecycle/tree/master/mu-plugins)
1. Set GitHub OAuth token if you develop a private theme or plugins
   `composer config github-oauth.github.com "$YOUR_GITHUB_TOKEN"`
1. Create [`public/wp-config.php`](https://github.com/szepeviktor/wordpress-website-lifecycle/blob/master/wp-config/wp-config.php)
   including  `WP_CONTENT_DIR` and `WP_CONTENT_URL` pointing to `public/wp-content`, and loading `vendor/autoload.php`
1. Set `WP_ENVIRONMENT_TYPE` environment variable
   (in [PHP-FPM configuration](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/phpfpm-pools/Skeleton-pool.conf) or in `public/wp-config.php`)
1. Issue `composer update --no-dev`
1. Administer your WordPress installation with [WP-CLI](https://make.wordpress.org/cli/handbook/guides/installing/)
   ```bash
   wp core install --title="WP" --admin_user="myname" --admin_email="user@example.com" --admin_password="12345"
   wp option update home "https://example.com"
   wp option update siteurl "https://example.com/project"
   ```

## WordPress core installation

These are possible variations.

- **`roots/wordpress-no-content` + `johnpbloch/wordpress-core-installer`**
- `johnpbloch/wordpress`
- `repositories.package` with current ZIP file from wordpress.org
- `roots/wordpress`

Packages provided by Roots point to wordpress.org ZIP files and git repositories.
