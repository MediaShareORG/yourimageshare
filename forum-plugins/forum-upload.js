/*!
 * YourImageShare Forum Upload Widget
 * https://yourimageshare.com/about/api
 *
 * Adds an "Upload Image" button next to post-editor textareas. On upload,
 * inserts [img]direct-url[/img] BBCode at the cursor position.
 *
 * Setup: set an API key before this script loads:
 *   <script>window.YIS_API_KEY = "YOUR_API_KEY";</script>
 *   <script src="https://yourimageshare.com/assets/js/forum-upload.js"></script>
 *
 * Advanced: call YISForumUpload.init({ apiKey, bbcode, selector }) manually
 * instead of relying on window.YIS_API_KEY / the automatic textarea scan.
 */
(function () {
    'use strict';

    var API_URL = 'https://yourimageshare.com/api';
    var DEFAULT_SELECTOR = 'textarea';
    var RESCAN_INTERVAL_MS = 1500;

    function init(options) {
        options = options || {};
        var apiKey = options.apiKey || window.YIS_API_KEY;
        var selector = options.selector || DEFAULT_SELECTOR;
        var bbcode = options.bbcode !== false;

        if (!apiKey) {
            console.error('YourImageShare upload widget: no API key configured (window.YIS_API_KEY is not set).');
            return;
        }

        attachAll(selector, apiKey, bbcode);
        // Forums frequently load the reply/quick-reply editor after the
        // initial page render (AJAX quick-reply, quote-loading, etc.), so
        // keep scanning for newly-added textareas rather than running once.
        setInterval(function () {
            attachAll(selector, apiKey, bbcode);
        }, RESCAN_INTERVAL_MS);
    }

    function attachAll(selector, apiKey, bbcode) {
        var textareas = document.querySelectorAll(selector);
        for (var i = 0; i < textareas.length; i++) {
            var textarea = textareas[i];
            if (textarea.dataset.yisAttached) continue;
            textarea.dataset.yisAttached = '1';
            attachButton(textarea, apiKey, bbcode);
        }
    }

    function attachButton(textarea, apiKey, bbcode) {
        var wrapper = document.createElement('div');
        wrapper.className = 'yis-upload-wrapper';
        wrapper.style.cssText = 'margin:4px 0;';

        var button = document.createElement('button');
        button.type = 'button';
        button.className = 'yis-upload-btn';
        button.textContent = 'Upload Image (YourImageShare)';
        button.style.cssText = 'padding:4px 10px;cursor:pointer;';

        var input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/jpeg,image/png,image/gif,image/webp,video/mp4,video/webm';
        input.style.display = 'none';

        button.addEventListener('click', function () {
            input.click();
        });

        input.addEventListener('change', function () {
            var file = input.files && input.files[0];
            if (!file) return;
            uploadFile(file, apiKey, textarea, button, bbcode);
            input.value = '';
        });

        wrapper.appendChild(button);
        wrapper.appendChild(input);
        textarea.parentNode.insertBefore(wrapper, textarea);
    }

    function uploadFile(file, apiKey, textarea, button, bbcode) {
        var originalText = button.textContent;
        button.textContent = 'Uploading...';
        button.disabled = true;

        var formData = new FormData();
        formData.append('uploads', file);

        fetch(API_URL, {
            method: 'POST',
            headers: { 'X-API-Key': apiKey },
            body: formData,
        })
            .then(function (res) {
                return res.json().then(function (json) {
                    return { ok: res.ok, json: json };
                });
            })
            .then(function (result) {
                if (!result.ok || result.json.type === 'error') {
                    throw new Error((result.json && result.json.errors) || 'Upload failed.');
                }
                insertAtCursor(textarea, formatLink(result.json.data.src, bbcode));
            })
            .catch(function (err) {
                alert('YourImageShare upload failed: ' + err.message);
            })
            .finally(function () {
                button.textContent = originalText;
                button.disabled = false;
            });
    }

    function formatLink(url, bbcode) {
        return bbcode ? '[img]' + url + '[/img]' : url;
    }

    function insertAtCursor(textarea, text) {
        var start = typeof textarea.selectionStart === 'number' ? textarea.selectionStart : textarea.value.length;
        var end = typeof textarea.selectionEnd === 'number' ? textarea.selectionEnd : textarea.value.length;
        var value = textarea.value;
        textarea.value = value.slice(0, start) + text + value.slice(end);
        textarea.focus();
        var newPos = start + text.length;
        textarea.setSelectionRange(newPos, newPos);
    }

    window.YISForumUpload = { init: init };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            init();
        });
    } else {
        init();
    }
})();
