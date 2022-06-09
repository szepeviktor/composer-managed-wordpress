<?php

/**
 * @wordpress-plugin
 * Plugin Name:     Disallow WordPress management (MU)
 * Plugin URI:      https://github.com/szepeviktor/debian-server-tools/tree/master/webserver/wordpress
 * Description:     Disallow core, plugin, theme installation as WordPress is managed by Composer.
 * Requires PHP:    7.4
 * Author:          Viktor Szépe
 * License:         MIT
 */

add_filter(
    'user_has_cap',
    static function ($capabilities) {
        return array_merge(
            $capabilities,
            [
                'install_plugins' => false,
                'install_themes' => false,
                // 'switch_themes' => false,
                'delete_plugins' => false,
                'delete_themes' => false,
                'update_core' => false,
                'update_plugins' => false,
                'update_themes' => false,
                'update_languages' => false,
                'install_languages' => false,
            ]
        );
    },
    PHP_INT_MAX,
    1
);
