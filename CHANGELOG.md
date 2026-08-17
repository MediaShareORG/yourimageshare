# Changelog

All notable changes to this repository (API docs, SDKs, MCP server, forum
plugins, and screenshot tool configs) are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Each SDK also has its own version, tracked in its `package.json`/
`pyproject.toml` (currently `yourimageshare` JS SDK 1.0.3, `yourimageshare`
Python SDK 1.0.3, `yourimageshare-mcp` 1.0.6, `yourimageshare-discord-bot`
0.1.0) - this log covers the repo as a whole rather than duplicating
per-package release notes.

## [Unreleased]

- Added `discord/` - a Discord bot (`/upload file:<attachment>
  [expires_in_days]`) wrapping the existing public API + JS SDK. v1 uploads
  under a single shared account (the bot's own API key), same model most
  paste-an-image-get-a-link Discord bots use; per-user linked accounts
  would need real Discord OAuth, noted as a real v2 rather than built here.
  Compiles clean under strict TypeScript; smoke-tested the upload/error
  path against the real live API with a deliberately bad key (confirmed
  the exact `401` error shape comes back correctly through the SDK). The
  Discord-specific half (slash command registration, interaction handling)
  still needs a real bot token to test end-to-end.
- Published `https://yourimageshare.com/openapi.json` - a real OpenAPI 3.1
  spec built from the actual `UploadController.php` source (not just the
  JS SDK's types), validated against the OpenAPI 3.1 JSON Schema. Linked
  from `/about/api` and the MCP README.
- Repositioned the MCP server's pitch from generic "for AI agents" to the
  concrete bug-report/PR-screenshot use case, on both `/about/api` and
  `mcp/README.md`.
- `yourimageshare-mcp` 1.0.6: fixed the actual cause of Smithery's 45/100
  quality score. `src/index.ts` was calling `process.exit(1)` if
  `YIS_API_KEY` wasn't set, *before* the server or any tool got
  registered - Smithery's quality scanner has no real credentials to
  give it, so the process almost certainly crashed before it could ever
  see the rich tool definitions added in 1.0.5, explaining a 0/40
  Capability Quality score despite Server Metadata scoring a clean
  35/35. Made the missing-key check non-fatal: tools now register and
  `tools/list` succeeds with zero credentials (verified directly, not
  assumed - spawned the built server with no `YIS_API_KEY` and confirmed
  all 3 tools list successfully); actual tool calls still fail cleanly
  through the existing API-error path (a 401 from the real API) if no
  valid key is set, same as before.
- `yourimageshare-mcp` 1.0.5: richer tool definitions to raise Smithery's
  quality score (was 45/100) - added MCP `annotations` (readOnlyHint /
  destructiveHint / idempotentHint / openWorldHint) and `outputSchema` to
  all 3 tools, server-level `title`/`description`/`websiteUrl`, and
  rewrote all 3 descriptions against Smithery's published Tool Definition
  Quality Score rubric (purpose clarity, usage guidelines, behavioral
  transparency, parameter semantics, conciseness, contextual
  completeness) - including documenting a real gotcha in the upload
  response shape (the `direct` field is actually the shareable *page*
  URL, not a direct file link; `src` is). Verified via a real MCP client
  connection (`tools/list`) that the schemas are well-formed before
  publishing, not just that it compiles.
- `yourimageshare-mcp` 1.0.4: added `mcpName` (`io.github.MediaShareORG/yourimageshare`
  - note the exact GitHub org casing; the registry's namespace check is
  case-sensitive, unlike GitHub login itself, so 1.0.3 shipped with a
  lowercased value that the registry rejected) to `package.json` and
  published `mcp/server.json`, to list the server on the official MCP
  Registry (registry.modelcontextprotocol.io). Also added `mcp/glama.json`
  and `mcp/manifest.json` (MCPB bundle manifest, used to publish to
  Smithery) in prior unreleased work.
- Added `CODE_OF_CONDUCT.md`, issue templates (bug report, feature request),
  and a pull request template, rounding out GitHub's community standards
  checklist.
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
