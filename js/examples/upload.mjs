// Example: upload a local file and print the direct link.
// Run with: YIS_API_KEY=... node examples/upload.mjs ./photo.jpg
import { YourImageShare } from '../dist/index.js';
import { blobFromFile } from '../dist/node.js';

const apiKey = process.env.YIS_API_KEY;
const path = process.argv[2];

if (!apiKey || !path) {
  console.error('Usage: YIS_API_KEY=... node examples/upload.mjs <file>');
  process.exit(1);
}

const client = new YourImageShare({ apiKey });
const blob = await blobFromFile(path);
const result = await client.upload(blob, { filename: path.split('/').pop() });

console.log(result.direct);
