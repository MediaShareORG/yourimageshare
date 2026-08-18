# YourImageShare Upload for phpBB

A real phpBB 3.2/3.3 extension. Adds an "Upload Image (YourImageShare)"
button next to the post editor - upload an image or short video and its
direct link is inserted as BBCode at your cursor.

## Install

1. Get your Upload-only key: sign in at [yourimageshare.com](https://yourimageshare.com),
   open "My account" > the API tab. It's the second key on that page,
   separate from your main API key - use it here, since this key ends up
   in every visitor's page source and it can only upload, never list or
   delete your uploads (your main key can do both, so keep that one out of
   anything rendered publicly).
2. Copy the `yourimageshare/` folder into your phpBB installation's `ext/`
   directory, so you end up with
   `ext/yourimageshare/forumupload/composer.json` etc.
3. In the Admin Control Panel, go to **Customise > Manage extensions** and
   enable "YourImageShare Upload".
4. Edit `ext/yourimageshare/forumupload/styles/all/template/event/overall_footer_after.html`
   and replace `YOUR_UPLOAD_ONLY_KEY` with your real upload-only key.

The button now appears automatically on every page with a post editor.

Full API docs: https://yourimageshare.com/about/api
