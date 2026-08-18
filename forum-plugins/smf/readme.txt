[b]YourImageShare Upload for SMF[/b]

Adds an "Upload Image (YourImageShare)" button next to the post editor.
Upload an image or short video and its direct link is inserted as BBCode
at your cursor - no separate tab, no manual copy-paste.

[b]Setup[/b]

1. Get your Upload-only key: sign in at yourimageshare.com, open "My
   account" > the API tab. It's the second key on that page, separate from
   your main API key - use it here, since this key only appears in
   every visitor's page source and it can only upload, never list or
   delete your uploads (your main key can do both, so keep that one out
   of anything rendered publicly).
2. After installing this package, edit
   [tt]Sources/yis_forumupload.php[/tt] and replace
   [tt]YOUR_UPLOAD_ONLY_KEY[/tt] with your real upload-only key.

That's it - the button appears automatically on every page with a post
editor.

Full API docs: https://yourimageshare.com/about/api
