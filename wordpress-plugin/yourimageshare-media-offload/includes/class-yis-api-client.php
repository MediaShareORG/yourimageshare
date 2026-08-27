<?php
/**
 * Thin wrapper around YourImageShare's REST API (see
 * https://github.com/MediaShareORG/yourimageshare-api/blob/main/API.md).
 * WordPress's HTTP API (WP_Http/wp_remote_post) has no built-in support for
 * multipart file uploads, so upload() builds the multipart/form-data body
 * by hand - a standard pattern for WP plugins talking to a REST upload
 * endpoint, not a YourImageShare-specific workaround.
 */

if (!defined('ABSPATH')) {
	die('This file cannot be accessed directly.');
}

class YIS_API_Client {

	/**
	 * Upload a local file. Returns the API's `data` object
	 * (id/type/path/src/direct) on success, or a WP_Error on failure -
	 * never throws, so a callback hooked into wp_generate_attachment_metadata
	 * can safely bail out and leave the local file alone.
	 *
	 * Uploads can be up to 200MB (video). Loading a file that size into PHP
	 * memory via file_get_contents() would be a real problem specifically
	 * for this plugin's target audience - low-resource shared hosting - so
	 * this streams the file from disk via cURL's CURLFile whenever the curl
	 * extension is available (near-universal on real hosting), falling back
	 * to WP_Http's manual multipart body (loads the file into memory) only
	 * when it isn't.
	 */
	public static function upload($file_path, $api_key) {
		if (!$api_key) {
			return new WP_Error('yis_no_key', __('No YourImageShare upload key configured.', 'yourimageshare-media-offload'));
		}
		if (!file_exists($file_path)) {
			return new WP_Error('yis_missing_file', __('Local file no longer exists.', 'yourimageshare-media-offload'));
		}

		if (function_exists('curl_init') && class_exists('CURLFile')) {
			return self::upload_via_curl($file_path, $api_key);
		}

		return self::upload_via_wp_http($file_path, $api_key);
	}

	private static function upload_via_curl($file_path, $api_key) {
		$mime = function_exists('mime_content_type') ? mime_content_type($file_path) : 'application/octet-stream';
		$filename = basename($file_path);

		$ch = curl_init();
		curl_setopt_array($ch, array(
			CURLOPT_URL => YIS_OFFLOAD_API_BASE,
			CURLOPT_POST => true,
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_TIMEOUT => 120,
			CURLOPT_HTTPHEADER => array('X-API-Key: ' . $api_key),
			CURLOPT_POSTFIELDS => array(
				'uploads' => new CURLFile($file_path, $mime, $filename),
			),
		));

		$body = curl_exec($ch);
		$errno = curl_errno($ch);
		$error = curl_error($ch);
		$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
		curl_close($ch);

		if ($errno) {
			return new WP_Error('yis_curl_error', $error);
		}

		return self::parse_response($body, $code);
	}

	private static function upload_via_wp_http($file_path, $api_key) {
		$boundary = wp_generate_password(24, false);
		$filename = basename($file_path);
		$file_contents = file_get_contents($file_path);
		if ($file_contents === false) {
			return new WP_Error('yis_read_failed', __('Could not read local file.', 'yourimageshare-media-offload'));
		}

		$mime = function_exists('mime_content_type') ? mime_content_type($file_path) : 'application/octet-stream';

		$body = "--{$boundary}\r\n";
		$body .= 'Content-Disposition: form-data; name="uploads"; filename="' . $filename . "\"\r\n";
		$body .= "Content-Type: {$mime}\r\n\r\n";
		$body .= $file_contents . "\r\n";
		$body .= "--{$boundary}--\r\n";

		$response = wp_remote_post(YIS_OFFLOAD_API_BASE, array(
			'timeout' => 60,
			'headers' => array(
				'X-API-Key' => $api_key,
				'Content-Type' => "multipart/form-data; boundary={$boundary}",
			),
			'body' => $body,
		));

		if (is_wp_error($response)) {
			return $response;
		}

		return self::parse_response(wp_remote_retrieve_body($response), wp_remote_retrieve_response_code($response));
	}

	private static function parse_response($raw_body, $code) {
		$json = json_decode($raw_body, true);

		if ($code === 429) {
			return new WP_Error('yis_rate_limited', __('YourImageShare API rate limit reached - try again shortly.', 'yourimageshare-media-offload'));
		}

		if ($code !== 200 || !is_array($json) || ($json['type'] ?? '') !== 'success') {
			$message = is_array($json) && isset($json['errors']) ? $json['errors'] : sprintf(
				/* translators: %d: HTTP status code */
				__('Unexpected response (HTTP %d).', 'yourimageshare-media-offload'), $code
			);
			return new WP_Error('yis_upload_failed', $message);
		}

		return $json['data'];
	}

	/**
	 * Delete a remote upload by id. Requires the full API key (the
	 * upload-only key intentionally can't delete) - see the Upload-only key
	 * section of API.md. Best-effort: failures are logged, not surfaced,
	 * since this runs from a delete_attachment hook with no UI to report to.
	 */
	public static function delete($remote_id, $full_api_key) {
		if (!$remote_id || !$full_api_key) {
			return false;
		}

		$response = wp_remote_request(YIS_OFFLOAD_API_BASE . '/' . rawurlencode($remote_id), array(
			'method' => 'DELETE',
			'timeout' => 15,
			'headers' => array('X-API-Key' => $full_api_key),
		));

		if (is_wp_error($response)) {
			error_log('[YourImageShare Media Offload] Remote delete failed for ' . $remote_id . ': ' . $response->get_error_message());
			return false;
		}

		$code = wp_remote_retrieve_response_code($response);
		if ($code !== 200) {
			error_log('[YourImageShare Media Offload] Remote delete for ' . $remote_id . ' returned HTTP ' . $code);
			return false;
		}

		return true;
	}
}
