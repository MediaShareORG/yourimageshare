# Security Policy

## Scope

This policy covers everything in this repository - the API documentation and
examples, the JavaScript/TypeScript SDK (`/js`), the Python SDK (`/python`),
the MCP server (`/mcp`), the forum plugins (`/forum-plugins`), and the
screenshot tool configs - as well as the live YourImageShare API and website
it documents (`yourimageshare.com` and `*.yourimageshare.com`).

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, report it privately to **security@yourimageshare.com**, or through
[yourimageshare.com/contact](https://yourimageshare.com/contact) if you'd
rather use the form. Include:

- A description of the vulnerability and its impact
- Steps to reproduce (proof-of-concept code or requests are welcome)
- The affected component (API endpoint, SDK, forum plugin, etc.) and version

We aim to acknowledge reports within 5 business days. We'll keep you updated
as we investigate and fix the issue, and we'll credit you in the fix
(changelog/release notes) if you'd like.

## Responsible disclosure

Please give us a reasonable amount of time to fix an issue before disclosing
it publicly. We're a small team, but we treat security reports as a priority
and will work with you on a disclosure timeline.

In scope for testing:

- Authentication and authorization bypass (API keys, account access)
- Injection, SSRF, and file-upload handling vulnerabilities in the API
- Vulnerabilities in the SDKs or MCP server that affect consumers of this
  repo's code

Please avoid:

- Automated scanning or load testing that could degrade service for other
  users
- Accessing, modifying, or deleting data that isn't yours
- Social engineering, phishing, or physical attacks against staff or users

## Supported versions

Only the latest published version of each SDK (`yourimageshare` on npm,
`yourimageshare` on PyPI, `yourimageshare-mcp` on npm) and the current
production API receive security fixes. There is no long-term support branch.
