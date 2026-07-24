<?php
/**
 * Runs once during package removal (SMF "code" operation).
 * Removes the persistent hook registered at install time.
 */

if (!function_exists('remove_integration_function'))
	require_once($sourcedir . '/Subs.php');

remove_integration_function('integrate_load_theme', 'yis_forumupload_load', '$sourcedir/yis_forumupload.php');
