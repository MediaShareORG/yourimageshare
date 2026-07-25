# Contributing

Thanks for considering a contribution. This repo holds the API docs, official
SDKs, MCP server, forum plugins, and screenshot tool configs for
YourImageShare - the API service itself is not open source and lives
elsewhere.

## What lives where

| Path | What it is |
|---|---|
| `README.md`, `API.md` | API reference documentation |
| `YourImageShare-API.postman_collection.json` | Postman collection |
| `openapi.yaml` | OpenAPI 3.0 spec |
| `js/` | JavaScript/TypeScript SDK (npm: `yourimageshare`) |
| `python/` | Python SDK (PyPI: `yourimageshare`) |
| `mcp/` | MCP server (npm: `yourimageshare-mcp`) |
| `forum-plugins/` | phpBB/SMF/MyBB/FluxBB/PunBB/ZetaBoards upload plugins |
| `*.sxcu`, `*-upload.sh`, `*-upload.ps1` | Screenshot tool configs (ShareX, Flameshot, Greenshot) |

## Reporting bugs / requesting features

Open a GitHub issue. For SDK or MCP server bugs, include the package
version, runtime (Node/Python version), and a minimal reproduction. For API
behavior questions or bugs in the live service, use
[yourimageshare.com/contact](https://yourimageshare.com/contact) instead -
this repo doesn't control the running API.

Found a security issue? Don't file a public issue - see
[SECURITY.md](SECURITY.md).

## Making changes

1. Fork the repo and create a branch off `main`.
2. Keep changes scoped to one SDK/plugin/doc at a time where possible - it
   makes review and versioning easier.
3. If you're changing SDK behavior, update that package's `README.md` and,
   if it affects the wire format, `API.md` and `openapi.yaml` too, so the
   three stay in sync.
4. Add an entry to [CHANGELOG.md](CHANGELOG.md) under an "Unreleased"
   section describing the change.

### JS/TS SDK (`js/`) and MCP server (`mcp/`)

```bash
cd js   # or mcp
npm install
npm run build   # compiles TypeScript with tsc; must pass with no errors
```

### Python SDK (`python/`)

```bash
cd python
python -m venv .venv && source .venv/bin/activate
pip install -e .
python -c "import yourimageshare"   # sanity check the package imports
```

### Forum plugins

Each plugin under `forum-plugins/<forum>/` follows that forum's native
plugin/extension structure. All six share
[`forum-plugins/forum-upload.js`](forum-plugins/forum-upload.js) - if you're
fixing something in the shared upload widget, test it against at least one
forum before opening a PR, and call out in the PR description which one(s)
you tested.

## Pull requests

- Describe what changed and why, not just what.
- Reference any related issue.
- Keep commit messages descriptive; we don't squash-merge, so clean history
  helps.
- CI (`.github/workflows/ci.yml`) runs the build steps above on JS, Python,
  and MCP - make sure it's green before requesting review.

## Coding standards

- TypeScript (`js/`, `mcp/`): match the existing style in `src/` - no
  linter is enforced yet, but code must compile under the existing
  `tsconfig.json` with no new `any` where a real type is easy to express.
- Python (`python/`): standard library + `requests` only; keep the SDK
  dependency-light, matching its current footprint.
- Docs (`README.md`, `API.md`): keep request/response examples runnable as
  shown (they're copy-pasted by users) and keep `README.md` and `API.md` in
  sync when endpoint behavior changes.

## License

By contributing, you agree your contribution is licensed under this repo's
[MIT license](LICENSE) (each SDK subpackage is also individually MIT
licensed).
