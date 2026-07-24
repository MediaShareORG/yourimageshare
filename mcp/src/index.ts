#!/usr/bin/env node
import { readFile } from 'node:fs/promises';
import { basename } from 'node:path';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { DEFAULT_BASE_URL, YourImageShareApiError, YourImageShareClient } from './client.js';

const apiKey = process.env.YIS_API_KEY;
if (!apiKey) {
  console.error('yourimageshare-mcp: YIS_API_KEY environment variable is required.');
  console.error('Get a key from the "API" tab at https://yourimageshare.com/my-account');
  process.exit(1);
}

const client = new YourImageShareClient(apiKey, process.env.YIS_BASE_URL ?? DEFAULT_BASE_URL);

const server = new McpServer({
  name: 'yourimageshare',
  version: '1.0.2',
});

function errorResult(err: unknown) {
  const message = err instanceof YourImageShareApiError ? `${err.message} (HTTP ${err.status})` : String(err);
  return { content: [{ type: 'text' as const, text: `Error: ${message}` }], isError: true };
}

server.registerTool(
  'upload_image',
  {
    title: 'Upload an image or video',
    description:
      'Upload an image or video to YourImageShare and get back a shareable link. ' +
      'Provide either `path` (a local file path readable by this server) or ' +
      '`base64` + `filename` (for clients with no local filesystem access), not both.',
    inputSchema: {
      path: z.string().optional().describe('Local file path to upload.'),
      base64: z.string().optional().describe('Base64-encoded file contents. Requires `filename`.'),
      filename: z.string().optional().describe('Filename to use. Required with `base64`; inferred from `path` otherwise.'),
      expiresIn: z
        .number()
        .int()
        .min(60)
        .max(2592000)
        .optional()
        .describe('Auto-delete after this many seconds (60 to 2,592,000 = 30 days). Omit for a permanent upload.'),
    },
  },
  async ({ path, base64, filename, expiresIn }) => {
    try {
      let blob: Blob;
      let name: string;

      if (path && base64) {
        return { content: [{ type: 'text', text: 'Error: provide only one of `path` or `base64`, not both.' }], isError: true };
      } else if (path) {
        const buffer = await readFile(path);
        blob = new Blob([buffer as unknown as BlobPart]);
        name = filename ?? basename(path);
      } else if (base64) {
        if (!filename) {
          return { content: [{ type: 'text', text: 'Error: `filename` is required when uploading via `base64`.' }], isError: true };
        }
        blob = new Blob([Buffer.from(base64, 'base64') as unknown as BlobPart]);
        name = filename;
      } else {
        return { content: [{ type: 'text', text: 'Error: provide either `path` or `base64` + `filename`.' }], isError: true };
      }

      const result = await client.upload(blob, name, expiresIn);
      return {
        content: [
          {
            type: 'text' as const,
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    } catch (err) {
      return errorResult(err);
    }
  },
);

server.registerTool(
  'list_uploads',
  {
    title: 'List your uploads',
    description: 'List your YourImageShare uploads, newest first. 50 per page.',
    inputSchema: {
      page: z.number().int().min(1).optional().describe('Page number. Defaults to 1.'),
    },
  },
  async ({ page }) => {
    try {
      const result = await client.list(page ?? 1);
      return { content: [{ type: 'text' as const, text: JSON.stringify(result, null, 2) }] };
    } catch (err) {
      return errorResult(err);
    }
  },
);

server.registerTool(
  'delete_upload',
  {
    title: 'Delete an upload',
    description: 'Permanently delete one of your YourImageShare uploads by id.',
    inputSchema: {
      id: z.string().describe('The upload id to delete (the `id` field returned by upload_image/list_uploads).'),
    },
  },
  async ({ id }) => {
    try {
      await client.delete(id);
      return { content: [{ type: 'text' as const, text: `Deleted ${id}.` }] };
    } catch (err) {
      return errorResult(err);
    }
  },
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error('yourimageshare-mcp: fatal error', err);
  process.exit(1);
});
