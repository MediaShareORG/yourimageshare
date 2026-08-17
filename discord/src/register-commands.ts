import { REST, Routes, SlashCommandBuilder } from 'discord.js';

/**
 * Registers the bot's slash commands with Discord. Run once after a command
 * definition changes (`npm run register-commands`) - not on every bot start,
 * since Discord treats this as a config push, not a runtime action.
 */

const token = process.env.DISCORD_TOKEN;
const clientId = process.env.DISCORD_CLIENT_ID;

if (!token || !clientId) {
  console.error('DISCORD_TOKEN and DISCORD_CLIENT_ID must be set.');
  process.exit(1);
}

const commands = [
  new SlashCommandBuilder()
    .setName('upload')
    .setDescription('Upload a file to YourImageShare and get back a shareable link')
    .addAttachmentOption((opt) =>
      opt.setName('file').setDescription('The image or video to upload').setRequired(true),
    )
    .addIntegerOption((opt) =>
      opt
        .setName('expires_in_days')
        .setDescription('Auto-delete after this many days (omit for a permanent upload)')
        .setMinValue(1)
        .setMaxValue(30)
        .setRequired(false),
    )
    .toJSON(),
];

const rest = new REST().setToken(token);

try {
  await rest.put(Routes.applicationCommands(clientId), { body: commands });
  console.log(`Registered ${commands.length} global command(s). Global registration can take up to an hour to propagate - register per-guild (Routes.applicationGuildCommands) instead while testing.`);
} catch (err) {
  console.error('Failed to register commands:', err);
  process.exit(1);
}
