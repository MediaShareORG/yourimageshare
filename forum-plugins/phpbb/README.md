# YourImageShare Upload for phpBB

A real phpBB 3.2/3.3 extension. Adds an "Upload Image (YourImageShare)"
button next to the post editor - upload an image or short video and its
direct link is inserted as BBCode at your cursor.

## Install

1. Get an API key: sign in at [yourimageshare.com](https://yourimageshare.com),
   open "My account" > the API tab.
2. Copy the `yourimageshare/` folder into your phpBB installation's `ext/`
   directory, so you end up with
   `ext/yourimageshare/forumupload/composer.json` etc.
3. In the Admin Control Panel, go to **Customise > Manage extensions** and
   enable "YourImageShare Upload".
4. Edit `ext/yourimageshare/forumupload/styles/all/template/event/overall_footer_after.html`
   and replace `YOUR_API_KEY` with your real key.

The button now appears automatically on every page with a post editor.

Full API docs: https://yourimageshare.com/about/api
