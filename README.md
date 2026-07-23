# YourImageShare API

Free JSON/REST API for [YourImageShare](https://yourimageshare.com) - a free
image and video hosting platform for anonymous and registered users. Use the
API to upload, list, and delete files programmatically instead of going
through the browser uploader.

- **Base URL:** `https://yourimageshare.com/api`
- **Auth:** an API key, sent as `?key=` or an `X-API-Key` header
- **Format:** JSON in and out, except uploads which are `multipart/form-data`
- **Full reference:** [API.md](API.md)
- **Live docs:** [yourimageshare.com/about/api](https://yourimageshare.com/about/api)
- **Postman collection:** [YourImageShare-API.postman_collection.json](YourImageShare-API.postman_collection.json)

## Get an API key

Sign in to your [account](https://yourimageshare.com/my-account) and open
the **API** tab. Your key is shown there, along with a **Regenerate**
button.

## Quick example

```bash
curl "https://yourimageshare.com/api?key=YOUR_API_KEY" \
  -F "uploads=@/path/to/photo.jpg"
```

```json
{
  "type": "success",
  "msg": "success",
  "data": {
    "id": "aB3xY9qRz1",
    "type": "image",
    "path": "https://i.yourimageshare.com/aB3xY9qRz1.webp",
    "src": "https://yourimageshare.com/ib/aB3xY9qRz1.webp",
    "direct": "https://yourimageshare.com/ib/aB3xY9qRz1"
  }
}
```

## Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/api` | Upload a file |
| `GET` | `/api` | List your uploads (paginated) |
| `DELETE` | `/api/{id}` | Delete one of your uploads |

Full request/response shapes, rate limits, error codes, and code samples in
curl, JavaScript, Python, PHP, and Go are in [API.md](API.md).

## Screenshot tools

Ready-made configs/scripts to upload straight from a screenshot tool, no
browser tab required:

- [`YourImageShare.sxcu`](YourImageShare.sxcu) - ShareX custom uploader
- [`yis-flameshot-upload.sh`](yis-flameshot-upload.sh) - Flameshot (Linux)
- [`yis-greenshot-upload.ps1`](yis-greenshot-upload.ps1) - Greenshot (Windows)

Setup instructions are in the comments at the top of each file, and on the
[live docs page](https://yourimageshare.com/about/api#screenshot-tools).

## Rate limits

Each API key gets 20 requests/minute and 500 requests/day by default, plus a
2,000/day ceiling per IP address as a backstop. Every response includes
`X-RateLimit-Limit`/`X-RateLimit-Remaining` headers; a `429` includes
`Retry-After`.

## Support

Questions or issues: [yourimageshare.com/contact](https://yourimageshare.com/contact).
