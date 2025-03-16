# Migration of WordPress installations

## Clone Staging to Production

Please see [Production-website.md](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/Production-website.md#migration)

- Remove development `wp_options`, use WP-CLI
- Delete unused Media files from filesystem and database
- See `humanmade/orphan-command`
- Try WP-Sweep plugin
- Optimize database `wp db optimize`

### Changing domain name

```shell
wp search-replace --precise --recurse-objects --all-tables-with-prefix "OLD" "NEW"
```

Replace items in this order.

1. `https://DOMAIN.TLD` no trailing slash
1. `http://DOMAIN.TLD` no trailing slash
1. `/home/PATH/TO/SITE` no trailing slash
1. `EMAIL@ADDRESS.ES` all addresses
1. `DOMAIN.TLD` now only the domain name

Flush permalinks and object cache.

```shell
wp rewrite flush --hard
wp cache flush
```

And edit constants in `wp-config.php`.

Web-based search & replace tool.

```shell
wget -O srdb.php https://github.com/interconnectit/Search-Replace-DB/raw/master/index.php
wget https://github.com/interconnectit/Search-Replace-DB/raw/master/srdb.class.php
```

## Moving settings from parent theme to child theme

```shell
wp option list --search="theme_mods_*" --fields=option_name
wp option get theme_mods_parent-theme --format=json | wp option update theme_mods_child-theme --format=json
```
