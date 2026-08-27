/**
 * Drives the "Offload existing media" bulk action: repeated small AJAX
 * batches (server processes a few files per request, see YIS_Bulk) rather
 * than one long-running request, since shared hosts commonly cap
 * max_execution_time well under what a full library would take. Backs off
 * for a full minute on a rate-limited response instead of hammering the
 * API - a real, expected outcome for a large library, not an edge case to
 * ignore.
 */
(function ($) {
	'use strict';

	var $startBtn = $('#yis-bulk-start');
	var $status = $('#yis-bulk-status');
	var $progressWrap = $('#yis-bulk-progress');
	var $progressBar = $('#yis-bulk-progress-bar');

	if (!$startBtn.length) {
		return;
	}

	var totalAtStart = 0;
	var totalDone = 0;
	var totalFailed = 0;
	var running = false;

	function ajax(action, data) {
		return $.post(yisOffload.ajaxUrl, $.extend({ action: action, nonce: yisOffload.nonce }, data));
	}

	function setProgress(remaining) {
		if (!totalAtStart) {
			return;
		}
		var done = totalAtStart - remaining;
		var pct = Math.min(100, Math.round((done / totalAtStart) * 100));
		$progressBar.css('width', pct + '%');
		$status.text(
			yisOffload.i18n.processing
				.replace('%1$d', done)
				.replace('%2$d', remaining)
		);
	}

	function runBatch() {
		if (!running) {
			return;
		}
		ajax('yis_bulk_batch', {}).done(function (response) {
			if (!response || !response.success) {
				$status.text(yisOffload.i18n.error);
				running = false;
				$startBtn.prop('disabled', false);
				return;
			}

			var data = response.data;
			totalDone += data.succeeded;
			totalFailed += data.failed;

			if (data.rate_limited) {
				$status.text(yisOffload.i18n.rateLimited);
				setTimeout(runBatch, 60000);
				return;
			}

			setProgress(data.remaining);

			if (data.remaining > 0) {
				setTimeout(runBatch, 1500);
			} else {
				running = false;
				$startBtn.prop('disabled', false);
				$status.text(
					yisOffload.i18n.done
						.replace('%1$d', totalDone)
						.replace('%2$d', totalFailed)
				);
			}
		}).fail(function () {
			$status.text(yisOffload.i18n.error);
			running = false;
			$startBtn.prop('disabled', false);
		});
	}

	$startBtn.on('click', function () {
		if (!window.confirm(yisOffload.i18n.confirmStart)) {
			return;
		}

		$startBtn.prop('disabled', true);
		$status.text(yisOffload.i18n.starting);
		$progressWrap.show();
		$progressBar.css('width', '0');
		totalDone = 0;
		totalFailed = 0;

		ajax('yis_bulk_count', {}).done(function (response) {
			totalAtStart = response && response.success ? response.data.count : 0;
			if (!totalAtStart) {
				$status.text(yisOffload.i18n.done.replace('%1$d', 0).replace('%2$d', 0));
				$startBtn.prop('disabled', false);
				return;
			}
			running = true;
			runBatch();
		});
	});
})(jQuery);
