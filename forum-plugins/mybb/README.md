# YourImageShare Upload for MyBB

A real MyBB plugin (1.8.x). Adds an "Upload Image (YourImageShare)"
button next to the post editor - upload an image or short video and its
direct link is inserted as BBCode at your cursor.

## Install

1. Get an API key: sign in at [yourimageshare.com](https://yourimageshare.com),
   open "My account" > the API tab.
2. Copy `inc/plugins/yourimageshare_upload.php` into your MyBB
   installation's `inc/plugins/` directory.
3. In the Admin Control Panel, go to **Configuration > Plugins** and
   activate "YourImageShare Upload".
4. Edit `inc/plugins/yourimageshare_upload.php` and replace `YOUR_API_KEY`
   near the top with your real key.

The button now appears automatically on every page with a post editor.

Full API docs: https://yourimageshare.com/about/api
