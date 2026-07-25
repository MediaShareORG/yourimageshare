# Changelog

All notable changes to this repository (API docs, SDKs, MCP server, forum
plugins, and screenshot tool configs) are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Each SDK also has its own version, tracked in its `package.json`/
`pyproject.toml` (currently `yourimageshare` JS SDK 1.0.3, `yourimageshare`
Python SDK 1.0.3, `yourimageshare-mcp` 1.0.2) - this log covers the repo as
a whole rather than duplicating per-package release notes.

## [Unreleased]

- Added `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`, this changelog, an
  `openapi.yaml` spec, and a CI workflow that builds the JS/TS and MCP
  packages and sanity-checks the Python package on every push/PR.

## 2026-07-24

- Added forum upload plugins: phpBB, SMF, MyBB, FluxBB, PunBB, ZetaBoards
  (`forum-plugins/`), sharing a common `forum-upload.js` widget.
- Added JS, Python, and MCP SDK source as subfolders (`js/`, `python/`,
  `mcp/`).
- Documented expiring uploads (`expires_in`) and added official client
  library links to `README.md`.

## 2026-07-23

- Initial API documentation (`README.md`, `API.md`).
- Added the Postman collection
  (`YourImageShare-API.postman_collection.json`).
- Added screenshot tool configs: ShareX (`YourImageShare.sxcu`), Flameshot
  (`yis-flameshot-upload.sh`), Greenshot (`yis-greenshot-upload.ps1`).
