<?php
/**
 * YourImageShare Upload for MyBB.
 * https://yourimageshare.com/about/api
 *
 * Adds an "Upload Image (YourImageShare)" button next to the post editor.
 * Set your real API key below (My account > API tab at yourimageshare.com)
 * before or after activating.
 */

if (!defined('IN_MYBB')) {
	die('This file cannot be accessed directly.');
}

define('YIS_FORUMUPLOAD_API_KEY', 'YOUR_API_KEY');

$plugins->add_hook('pre_output_page', 'yourimageshare_upload_inject');

function yourimageshare_upload_inject($contents)
{
	$snippet = '
	<script>window.YIS_API_KEY = ' . json_encode(YIS_FORUMUPLOAD_API_KEY) . ';</script>
	<script src="https://yourimageshare.com/assets/js/forum-upload.js"></script>
	</head>';

	$contents = str_replace('</head>', $snippet, $contents, $count);

	// Fallback for templates without a </head> tag in this particular
	// rendered page - inject right before the closing </body> instead.
	if ($count === 0) {
		$contents = str_replace('</body>', str_replace('</head>', '', $snippet) . '</body>', $contents);
	}

	return $contents;
}

function yourimageshare_upload_info()
{
	return array(
		'name'          => 'YourImageShare Upload',
		'description'   => 'Adds a YourImageShare upload button to the post editor - upload images or video and insert a direct link without leaving the page.',
		'website'       => 'https://yourimageshare.com/about/api',
		'author'        => 'YourImageShare',
		'authorsite'    => 'https://yourimageshare.com',
		'version'       => '1.0.0',
		'compatibility' => '18*',
	);
}

function yourimageshare_upload_activate()
{
}

function yourimageshare_upload_deactivate()
{
}
