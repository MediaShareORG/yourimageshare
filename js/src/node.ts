import { readFile } from 'node:fs/promises';

/**
 * Node-only helper: read a local file into a Blob suitable for `YourImageShare#upload()`.
 * Kept in a separate entry point (`yourimageshare/node`) so the main package stays
 * dependency-free and safe to bundle for browsers, which have no `fs` module.
 */
export async function blobFromFile(path: string, type?: string): Promise<Blob> {
  const buffer = await readFile(path);
  return new Blob([buffer], type ? { type } : undefined);
}
