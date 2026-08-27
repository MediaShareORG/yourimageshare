=== YourImageShare Media Offload ===
Contributors: yourimageshare
Tags: media offload, image hosting, video hosting, storage
Requires at least: 5.6
Tested up to: 6.6
Requires PHP: 7.4
Stable tag: 1.1.0
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Running out of hosting storage? Offload your Media Library to YourImageShare - free image and video hosting - automatically, no workflow change.

== Description ==

Shared hosting storage quotas fill up fast once a site has a few years of
blog images and video. This plugin sends Media Library uploads to
[YourImageShare](https://yourimageshare.com) - a free, no-account-required
image and video host - and deletes the local copy once the upload succeeds,
so your storage usage stops growing.

Everything keeps working normally: the block editor, Add Media, featured
images, galleries. There's no shortcode to remember and no separate
upload step - you use WordPress exactly like you always have, media just
lives on YourImageShare's servers instead of your own disk.

**What it does**

* Hooks into the real Media Library upload flow (not a separate button/shortcode) - images and video offload automatically when uploaded
* Deletes the original file *and* every generated thumbnail size from local disk once the remote copy is confirmed - this is what actually frees up space
* Rewrites every attachment URL WordPress generates (`wp_get_attachment_url`, featured images, block editor, REST API) to point at the YourImageShare-hosted file
* Real width/height are captured before the local file is removed, so offloaded images don't cause layout shift
* **Bulk-offloads your existing Media Library**, not just new uploads - a Media Library that's already full is the actual reason most people install a plugin like this
* **Restore any offloaded file back to local storage** at any time, from a row action in the Media Library or the attachment details panel - offloading is not a one-way door
* A Media Library column shows which files are offloaded vs. still local, with a one-click "Offload now" action for anything not yet offloaded
* Failed offloads are shown as a dismissible admin notice with the reason, not silently swallowed
* Tracks and displays how much storage you've actually saved
* Optional: delete the remote copy too when you delete an attachment in WordPress

**What it intentionally doesn't do**

YourImageShare serves one file per upload rather than a set of pre-sized
thumbnail variants, so this plugin doesn't generate a `srcset` for
offloaded images (it's suppressed rather than shipping broken links to
deleted local files). If you rely heavily on responsive `srcset` for
offloaded images specifically, keep that in mind.

**Free API key required**

You'll need a free YourImageShare account and an Upload-only API key
(this plugin's settings page links straight to it). No account is
required to use YourImageShare itself, but an account is what gives you
an API key.

== Installation ==

1. Install and activate the plugin.
2. Create a free account at [yourimageshare.com](https://yourimageshare.com), open **My Account > API**, and copy the **Upload-only key**.
3. Go to **Media Offload** in the admin menu, paste the key in, and save.
4. Upload an image or video to your Media Library as usual - it now offloads automatically.
5. Optional: use the **Offload existing media** button on the same page to offload everything already in your library.

== Frequently Asked Questions ==

= Does this work with the block editor? =

Yes. Offloaded media resolves through WordPress's normal attachment
functions, so it works anywhere an attachment is used: the block editor,
Add Media, featured images, galleries, REST API responses.

= What happens to images I uploaded before installing this plugin? =

They're left alone until you choose to offload them. Use the **Offload
existing media** button on the plugin's settings page to process your
whole existing library in the background, in small batches, respecting
the API's rate limits. New uploads offload automatically either way.

= Can I get a file back if I change my mind? =

Yes. Every offloaded file has a **Restore to local** action (Media Library
row actions, or the attachment details panel) that downloads it back to
your server and clears the offload status - WordPress treats it as a
completely normal local attachment again afterward.

= Is my upload key safe to store here? =

The settings page asks for your **Upload-only key** specifically, not your
main API key - it can only upload on your behalf, never list or delete
your account's uploads. The optional full API key (only needed if you turn
on remote deletion, or choose to delete a remote copy while restoring) has
more access, so only add that one if you actually want that behavior.

= What if the upload to YourImageShare fails? =

The local file is left exactly as WordPress created it - nothing is
deleted unless the remote upload is confirmed successful first. Failures
show up as a dismissible notice on the Media Library and plugin settings
screens with the reason, rather than failing silently.

== Privacy ==

This plugin sends the media file itself - and nothing else - to
YourImageShare's public API (`https://yourimageshare.com/api`) whenever an
offload happens, using the API key you configure. No post content, user
data, or site information is ever transmitted, and nothing is sent unless
an API key is set. See [YourImageShare's Privacy Policy](https://yourimageshare.com/about/privacy-policy)
for how uploaded files are handled once they reach YourImageShare.

== Screenshots ==

1. Settings page - API key, toggles, and running storage-saved total.
2. Bulk-offload progress for an existing Media Library.
3. Media Library list view showing offload status per file.

== Changelog ==

= 1.1.0 =
* Bulk-offload for existing Media Library items, processed in small rate-limit-aware batches.
* Restore-to-local action for any offloaded file (Media Library row action + attachment details panel).
* Media Library status column and per-file "Offload now" action.
* Dismissible admin notice for offload failures, with reason shown.
* Dedicated top-level admin menu item instead of a Settings submenu.

= 1.0.0 =
* Initial release.
