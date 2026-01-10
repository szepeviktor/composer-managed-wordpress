<?php

// Fix get_home_path() https://core.trac.wordpress.org/ticket/52575
$_SERVER['SCRIPT_FILENAME'] = __DIR__ . '/project/index.php';

/** Tell WordPress to load the WordPress theme and output it. */
define('WP_USE_THEMES', true);

/** Load the WordPress Environment and Template. */
require __DIR__ . '/project/wp-blog-header.php';
