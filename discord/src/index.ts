import { Client, GatewayIntentBits, EmbedBuilder } from 'discord.js';
import { YourImageShare, YourImageShareError } from 'yourimageshare';

const discordToken = process.env.DISCORD_TOKEN;
const apiKey = process.env.YIS_API_KEY;

if (!discordToken) {
  console.error('DISCORD_TOKEN environment variable is not set.');
  process.exit(1);
}
if (!apiKey) {
  console.error('YIS_API_KEY environment variable is not set. Get one from the "API" tab at https://yourimageshare.com/my-account');
  process.exit(1);
}

/**
 * v1 uploads under a single shared YourImageShare account (this bot's own
 * API key) - every upload from every server this bot is in lands in the
 * same account, same as how most "paste an image, get a link" Discord bots
 * work. Per-user linked accounts would need real OAuth plumbing this
 * project doesn't have yet - noted as a real v2, not built here.
 */
const yis = new YourImageShare({ apiKey });

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once('clientReady', () => {
  console.log(`Logged in as ${client.user?.tag}`);
});

client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand() || interaction.commandName !== 'upload') {
    return;
  }

  const attachment = interaction.options.getAttachment('file', true);
  const expiresInDays = interaction.options.getInteger('expires_in_days');

  await interaction.deferReply();

  try {
    const res = await fetch(attachment.url);
    if (!res.ok) {
      throw new Error(`Discord CDN fetch failed (HTTP ${res.status})`);
    }
    const buffer = await res.arrayBuffer();

    const result = await yis.upload(buffer, {
      filename: attachment.name,
      expiresIn: expiresInDays ? expiresInDays * 86400 : undefined,
    });

    const embed = new EmbedBuilder()
      .setColor(0x2b6cb0)
      .setTitle('Uploaded')
      .addFields(
        { name: 'Direct link', value: result.src },
        { name: 'Page link', value: result.direct },
      )
      .setFooter({
        text: result.expires_at ? `Expires ${result.expires_at}` : 'Permanent upload',
      });
    if (result.type === 'image') {
      embed.setImage(result.src);
    }

    await interaction.editReply({ embeds: [embed] });
  } catch (err) {
    const message =
      err instanceof YourImageShareError
        ? `YourImageShare API error: ${err.message}`
        : err instanceof Error
          ? err.message
          : 'Unknown error';
    await interaction.editReply({ content: `Upload failed: ${message}` });
  }
});

client.login(discordToken);
