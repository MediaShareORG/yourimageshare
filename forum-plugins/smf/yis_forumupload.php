<?php
/**
 * YourImageShare Upload for SMF.
 * https://yourimageshare.com/about/api
 *
 * Set your real API key below (My account > API tab at yourimageshare.com),
 * then reinstall/rebuild the package cache if the change doesn't show up.
 */

if (!defined('SMF'))
	die('No direct access.');

function yis_forumupload_load()
{
	global $context;

	$api_key = 'YOUR_API_KEY';

	$context['html_headers'] .= '
	<script>window.YIS_API_KEY = ' . json_encode($api_key) . ';</script>
	<script src="https://yourimageshare.com/assets/js/forum-upload.js"></script>';
}
