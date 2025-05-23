<?php

require_once ABSPATH . WPINC . '/functions.php';

header('Retry-After: 10');

// Copy of https://developer.wordpress.org/reference/functions/_default_wp_die_handler/
// wp_die(
//     '<h1>In maintenance mode</h1><p>Will come back online in seconds.</p>',
//     'Maintenance',
//     ['response' => 503]
// );

status_header(503);
header('Content-Type: text/html; charset=utf-8');
nocache_headers();

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="viewport" content="width=device-width">
    <title>Maintenance</title>
    <style type="text/css">
        html {
            background: #f1f1f1;
        }
        body {
            background: #fff;
            border: 1px solid #ccd0d4;
            color: #444;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif;
            margin: 2em auto;
            padding: 1em 2em;
            max-width: 700px;
            -webkit-box-shadow: 0 1px 1px rgba(0, 0, 0, .04);
            box-shadow: 0 1px 1px rgba(0, 0, 0, .04);
        }
        h1 {
            border-bottom: 1px solid #dadada;
            clear: both;
            color: #666;
            font-size: 24px;
            margin: 30px 0 0 0;
            padding: 0;
            padding-bottom: 7px;
        }
        #error-page {
            margin-top: 50px;
        }
        #error-page p,
        #error-page .wp-die-message {
            font-size: 14px;
            line-height: 1.5;
            margin: 25px 0 20px;
        }
        #error-page code {
            font-family: Consolas, Monaco, monospace;
        }
        ul li {
            margin-bottom: 10px;
            font-size: 14px ;
        }
        a {
            color: #0073aa;
        }
        a:hover,
        a:active {
            color: #006799;
        }
        a:focus {
            color: #124964;
            -webkit-box-shadow: 0 0 0 1px #5b9dd9, 0 0 2px 1px rgba(30, 140, 190, 0.8);
            box-shadow: 0 0 0 1px #5b9dd9, 0 0 2px 1px rgba(30, 140, 190, 0.8);
            outline: none;
        }
        .button {
            background: #f3f5f6;
            border: 1px solid #016087;
            color: #016087;
            display: inline-block;
            text-decoration: none;
            font-size: 13px;
            line-height: 2;
            height: 28px;
            margin: 0;
            padding: 0 10px 1px;
            cursor: pointer;
            -webkit-border-radius: 3px;
            -webkit-appearance: none;
            border-radius: 3px;
            white-space: nowrap;
            -webkit-box-sizing: border-box;
            -moz-box-sizing: border-box;
            box-sizing: border-box;

            vertical-align: top;
        }

        .button.button-large {
            line-height: 2.30769231;
            min-height: 32px;
            padding: 0 12px;
        }

        .button:hover,
        .button:focus {
            background: #f1f1f1;
        }

        .button:focus {
            background: #f3f5f6;
            border-color: #007cba;
            -webkit-box-shadow: 0 0 0 1px #007cba;
            box-shadow: 0 0 0 1px #007cba;
            color: #016087;
            outline: 2px solid transparent;
            outline-offset: 0;
        }

        .button:active {
            background: #f3f5f6;
            border-color: #7e8993;
            -webkit-box-shadow: none;
            box-shadow: none;
        }
    </style>
</head>
<body id="error-page">
    <h1>In maintenance mode</h1>
    <p>Will come back online in seconds.</p>
</body>
</html>
