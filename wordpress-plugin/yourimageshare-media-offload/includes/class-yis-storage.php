<?php
/**
 * Local-disk accounting: sums up every file an attachment occupies
 * (original + every generated thumbnail/intermediate size), deletes them
 * once the remote copy is confirmed, and keeps a running total so the
 * settings page can show real "storage saved" numbers - the actual selling
 * point of this plugin over a generic uploader.
 */

if (!defined('ABSPATH')) {
	die('This file cannot be accessed directly.');
}

class YIS_Storage {

	/**
	 * Total on-disk bytes for this attachment right now: the original file
	 * plus every size in $metadata['sizes']. Must be called BEFORE
	 * delete_local_files() - there's nothing left to measure after.
	 */
	public static function calculate_local_bytes($file_path, $metadata) {
		$total = 0;

		if (file_exists($file_path)) {
			$total += filesize($file_path);
		}

		if (!empty($metadata['sizes']) && is_array($metadata['sizes'])) {
			$dir = dirname($file_path);
			foreach ($metadata['sizes'] as $size) {
				if (empty($size['file'])) {
					continue;
				}
				$size_path = $dir . '/' . $size['file'];
				if (file_exists($size_path)) {
					$total += filesize($size_path);
				}
			}
		}

		return $total;
	}

	/**
	 * Deletes the original file and every generated intermediate size from
	 * local disk. This is the actual space-saving mechanism - offloading
	 * alone doesn't help a storage-constrained host unless the local copy
	 * genuinely goes away afterward.
	 */
	public static function delete_local_files($file_path, $metadata) {
		$deleted = 0;

		if (file_exists($file_path)) {
			if (@unlink($file_path)) {
				$deleted++;
			}
		}

		if (!empty($metadata['sizes']) && is_array($metadata['sizes'])) {
			$dir = dirname($file_path);
			foreach ($metadata['sizes'] as $size) {
				if (empty($size['file'])) {
					continue;
				}
				$size_path = $dir . '/' . $size['file'];
				if (file_exists($size_path) && @unlink($size_path)) {
					$deleted++;
				}
			}
		}

		return $deleted;
	}

	public static function record_savings($bytes) {
		if ($bytes <= 0) {
			return;
		}
		$total = (int) get_option('yis_offload_bytes_saved', 0);
		update_option('yis_offload_bytes_saved', $total + $bytes, false);
		$count = (int) get_option('yis_offload_files_offloaded', 0);
		update_option('yis_offload_files_offloaded', $count + 1, false);
	}

	public static function format_bytes($bytes) {
		$bytes = max(0, (int) $bytes);
		$units = array('B', 'KB', 'MB', 'GB', 'TB');
		$i = 0;
		while ($bytes >= 1024 && $i < count($units) - 1) {
			$bytes /= 1024;
			$i++;
		}
		return round($bytes, $i === 0 ? 0 : 1) . ' ' . $units[$i];
	}
}
