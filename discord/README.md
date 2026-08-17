# yourimageshare-discord-bot

A Discord bot for [YourImageShare](https://yourimageshare.com): `/upload` a file, get back a
shareable link, right in the channel - no leaving Discord to visit the site.

## What it does

`/upload file:<attachment> [expires_in_days:<1-30>]` uploads the attachment via the
[YourImageShare API](https://yourimageshare.com/about/api) and replies with the direct link and
page link. Images render inline in the reply embed.

## v1 limitation, on purpose

Every upload from every server this bot is in lands in **one shared YourImageShare account** (the
bot's own `YIS_API_KEY`) - same model most "paste an image, get a link" Discord bots use. Per-user
linked accounts would need real Discord OAuth + a token-storage layer this project doesn't have
yet; not built here, flagged as a real v2 rather than assumed out of scope.

Discord's own attachment size limit (25MB on a non-boosted server, higher on boosted ones) is the
practical ceiling in most servers - well under YourImageShare's own 200MB cap, so it's rarely the
binding constraint.

## Setup

1. Create an application at the
   [Discord Developer Portal](https://discord.com/developers/applications), add a Bot, copy its
   token.
2. Get a YourImageShare API key from the **API** tab at
   [yourimageshare.com/my-account](https://yourimageshare.com/my-account).
3. Copy `.env.example` to `.env` and fill in `DISCORD_TOKEN`, `DISCORD_CLIENT_ID` (the
   application's ID, General Information tab), and `YIS_API_KEY`.
4. `npm install && npm run build`
5. `npm run register-commands` - registers `/upload` globally (can take up to an hour to
   propagate; register per-guild instead while iterating, see the comment in
   `src/register-commands.ts`).
6. Invite the bot to a server with the `bot` and `applications.commands` OAuth2 scopes, then
   `npm start`.

## Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `DISCORD_TOKEN` | yes | Bot token from the Developer Portal. |
| `DISCORD_CLIENT_ID` | yes (for `register-commands` only) | The application's ID. |
| `YIS_API_KEY` | yes | The shared YourImageShare account uploads land in. |

## License

MIT
