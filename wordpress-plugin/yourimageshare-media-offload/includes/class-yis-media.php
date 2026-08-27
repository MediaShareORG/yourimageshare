<?php
/**
 * Wires the offload into WordPress's real media pipeline, not a parallel
 * shortcode/button workflow: hooking wp_generate_attachment_metadata,
 * wp_get_attachment_url, image_downsize, and wp_calculate_image_srcset
 * means every existing way of using an attachment - Add Media, the block
 * editor, featured images, galleries, REST API responses - resolves to the
 * remote URL automatically. No content author has to do anything
 * differently.
 */

if (!defined('ABSPATH')) {
	die('This file cannot be accessed directly.');
}

class YIS_Media {

	const META_URL = '_yis_remote_url';
	const META_ID = '_yis_remote_id';
	const META_TYPE = '_yis_remote_type';
	const META_WIDTH = '_yis_remote_width';
	const META_HEIGHT = '_yis_remote_height';

	public static function init() {
		add_filter('wp_generate_attachment_metadata', array(__CLASS__, 'on_generate_attachment_metadata'), 999, 2);
		add_filter('wp_get_attachment_url', array(__CLASS__, 'filter_attachment_url'), 10, 2);
		add_filter('image_downsize', array(__CLASS__, 'filter_image_downsize'), 10, 3);
		add_filter('wp_calculate_image_srcset', array(__CLASS__, 'filter_srcset'), 10, 5);
		add_action('delete_attachment', array(__CLASS__, 'maybe_delete_remote'));
	}

	public static function is_offloaded($attachment_id) {
		return (bool) get_post_meta($attachment_id, self::META_URL, true);
	}

	public static function is_supported($attachment_id) {
		return in_array(get_post_mime_type($attachment_id), yis_offload_supported_mime_types(), true);
	}

	/**
	 * Thin wrapper: runs after WordPress has already saved the original
	 * file and generated every registered thumbnail/intermediate size, and
	 * only fires automatically when the "offload new uploads" setting is
	 * on. The actual offload logic lives in offload_attachment() so the
	 * bulk-offload feature (for a site's existing library) can call the
	 * exact same code path instead of a parallel copy.
	 */
	public static function on_generate_attachment_metadata($metadata, $attachment_id) {
		if (get_option('yis_offload_enabled', '1') !== '1') {
			return $metadata;
		}
		self::offload_attachment($attachment_id, $metadata);
		return $metadata;
	}

	/**
	 * Uploads one attachment to YourImageShare and (per settings) deletes
	 * the local copy. Safe to call directly - used by the automatic
	 * new-upload hook above and by YIS_Bulk's existing-media processor.
	 *
	 * @param int        $attachment_id
	 * @param array|null $metadata Pass the metadata array when already
	 *                             available (the generate-metadata hook has
	 *                             it); left null it's read fresh via
	 *                             wp_get_attachment_metadata() - the path
	 *                             the bulk processor uses for
	 *                             already-existing attachments.
	 * @return true|WP_Error
	 */
	public static function offload_attachment($attachment_id, $metadata = null) {
		if (self::is_offloaded($attachment_id)) {
			return true;
		}
		if (!self::is_supported($attachment_id)) {
			return new WP_Error('yis_unsupported_type', __('File type not supported by YourImageShare.', 'yourimageshare-media-offload'));
		}

		$file_path = get_attached_file($attachment_id);
		if (!$file_path || !file_exists($file_path)) {
			return new WP_Error('yis_missing_file', __('Local file no longer exists.', 'yourimageshare-media-offload'));
		}

		if ($metadata === null) {
			$metadata = wp_get_attachment_metadata($attachment_id);
			if (!is_array($metadata)) {
				$metadata = array();
			}
		}

		$upload_key = get_option('yis_offload_upload_key', '');
		$result = YIS_API_Client::upload($file_path, $upload_key);

		if (is_wp_error($result)) {
			YIS_Notices::record_failure($attachment_id, $result->get_error_message());
			return $result;
		}

		$mime = get_post_mime_type($attachment_id);

		// Capture real dimensions before the local file (the only place we
		// can read them from) is deleted - the API response doesn't include
		// them, and image_downsize()/srcset need real numbers to avoid
		// laying out a blank box or lying to browsers about image size.
		$width = 0;
		$height = 0;
		if (strpos($mime, 'image/') === 0) {
			$size_info = @getimagesize($file_path);
			if ($size_info) {
				$width = (int) $size_info[0];
				$height = (int) $size_info[1];
			}
		} elseif (!empty($metadata['width']) && !empty($metadata['height'])) {
			$width = (int) $metadata['width'];
			$height = (int) $metadata['height'];
		}

		update_post_meta($attachment_id, self::META_URL, esc_url_raw($result['path']));
		update_post_meta($attachment_id, self::META_ID, sanitize_text_field($result['id']));
		update_post_meta($attachment_id, self::META_TYPE, sanitize_text_field($result['type']));
		if ($width && $height) {
			update_post_meta($attachment_id, self::META_WIDTH, $width);
			update_post_meta($attachment_id, self::META_HEIGHT, $height);
		}

		if (get_option('yis_offload_delete_local', '1') === '1') {
			$bytes = YIS_Storage::calculate_local_bytes($file_path, $metadata);
			YIS_Storage::delete_local_files($file_path, $metadata);
			YIS_Storage::record_savings($bytes);
			update_post_meta($attachment_id, '_yis_local_deleted', 1);
		}

		YIS_Notices::clear_failure($attachment_id);

		return true;
	}

	public static function filter_attachment_url($url, $attachment_id) {
		$remote = get_post_meta($attachment_id, self::META_URL, true);
		return $remote ? $remote : $url;
	}

	/**
	 * Short-circuits WP's size-specific image lookup. YourImageShare serves
	 * one file per upload, not a set of pre-sized variants, so every
	 * requested $size gets the same remote URL - real width/height (from
	 * the original, captured pre-delete) still ships so <img> tags don't
	 * regress on CLS, just without a genuinely smaller file for "thumbnail".
	 */
	public static function filter_image_downsize($downsize, $attachment_id, $size) {
		$remote = get_post_meta($attachment_id, self::META_URL, true);
		if (!$remote) {
			return $downsize;
		}
		$width = (int) get_post_meta($attachment_id, self::META_WIDTH, true);
		$height = (int) get_post_meta($attachment_id, self::META_HEIGHT, true);
		return array($remote, $width, $height, false);
	}

	/**
	 * No real multi-resolution variants exist remotely, so a srcset built
	 * from local intermediate-size paths that no longer exist would just be
	 * broken links - suppress it rather than ship something wrong.
	 */
	public static function filter_srcset($sources, $size_array, $image_src, $image_meta, $attachment_id) {
		if (self::is_offloaded($attachment_id)) {
			return false;
		}
		return $sources;
	}

	public static function maybe_delete_remote($attachment_id) {
		if (get_option('yis_offload_delete_remote_on_trash', '0') !== '1') {
			return;
		}
		$remote_id = get_post_meta($attachment_id, self::META_ID, true);
		if (!$remote_id) {
			return;
		}
		$full_key = get_option('yis_offload_full_key', '');
		YIS_API_Client::delete($remote_id, $full_key);
	}
}
