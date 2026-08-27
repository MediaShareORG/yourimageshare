<?php
/**
 * Offloading only new uploads (the original v1 scope) misses the actual
 * reason most people would install this plugin: a Media Library that's
 * ALREADY eating the storage quota. This processes the existing library in
 * small batches over repeated AJAX calls (never one long-running request -
 * shared hosts commonly cap max_execution_time well under what a full
 * library would need) and stops early on a 429 so the browser-side loop
 * can back off instead of hammering a rate limit.
 */

if (!defined('ABSPATH')) {
	die('This file cannot be accessed directly.');
}

class YIS_Bulk {

	const BATCH_SIZE = 3;

	public static function init() {
		add_action('wp_ajax_yis_bulk_count', array(__CLASS__, 'ajax_count'));
		add_action('wp_ajax_yis_bulk_batch', array(__CLASS__, 'ajax_batch'));
	}

	private static function pending_query($limit) {
		return new WP_Query(array(
			'post_type' => 'attachment',
			'post_status' => 'inherit',
			'posts_per_page' => $limit,
			'fields' => 'ids',
			'post_mime_type' => yis_offload_supported_mime_types(),
			'meta_query' => array(
				array(
					'key' => YIS_Media::META_URL,
					'compare' => 'NOT EXISTS',
				),
			),
			'no_found_rows' => $limit > 0,
		));
	}

	public static function ajax_count() {
		check_ajax_referer('yis_media_action', 'nonce');
		if (!current_user_can('upload_files')) {
			wp_send_json_error(array('message' => __('Permission denied.', 'yourimageshare-media-offload')), 403);
		}

		$query = self::pending_query(-1);
		wp_send_json_success(array('count' => $query->found_posts));
	}

	public static function ajax_batch() {
		check_ajax_referer('yis_media_action', 'nonce');
		if (!current_user_can('upload_files')) {
			wp_send_json_error(array('message' => __('Permission denied.', 'yourimageshare-media-offload')), 403);
		}
		if (!get_option('yis_offload_upload_key', '')) {
			wp_send_json_error(array('message' => __('No upload key configured.', 'yourimageshare-media-offload')));
		}

		$query = self::pending_query(self::BATCH_SIZE);
		$succeeded = 0;
		$failed = 0;
		$rate_limited = false;

		foreach ($query->posts as $attachment_id) {
			$result = YIS_Media::offload_attachment($attachment_id);
			if (is_wp_error($result)) {
				if ($result->get_error_code() === 'yis_rate_limited') {
					$rate_limited = true;
					break;
				}
				$failed++;
				continue;
			}
			$succeeded++;
		}

		$remaining = self::pending_query(-1)->found_posts;

		wp_send_json_success(array(
			'succeeded' => $succeeded,
			'failed' => $failed,
			'rate_limited' => $rate_limited,
			'remaining' => (int) $remaining,
		));
	}
}
