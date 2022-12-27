# WordPress installations migration

### Clone Staging to Production

Please see [Production-website.md](https://github.com/szepeviktor/debian-server-tools/blob/master/webserver/Production-website.md#migration)

- Remove development wp_options -> Option Inspector
- Delete unused Media files @TODO `for $m in files; search $m in DB;`
- `wp db optimize`
- WP-Sweep

#### Changing domain name

```bash
wp search-replace --precise --recurse-objects --all-tables-with-prefix ...
```

1. https://DOMAIN.TLD (no trailing slash)
1. /home/PATH/TO/SITE (no trailing slash)
1. EMAIL@ADDRESS.ES (all addresses)
1. DOMAIN.TLD (now without https)

And manually replace constants in `wp-config.php`

Web-based search & replace tool:

```bash
wget -O srdb.php https://github.com/interconnectit/Search-Replace-DB/raw/master/index.php
wget https://github.com/interconnectit/Search-Replace-DB/raw/master/srdb.class.php
```

