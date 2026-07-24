<?php
/**
 * Runs once during package installation (SMF "code" operation).
 * Registers the integrate_load_theme hook persistently so it fires on
 * every page load from now on, without editing any core template files.
 */

if (!function_exists('add_integration_function'))
	require_once($sourcedir . '/Subs.php');

require_once($sourcedir . '/yis_forumupload.php');

add_integration_function('integrate_load_theme', 'yis_forumupload_load', '$sourcedir/yis_forumupload.php', false, true);
