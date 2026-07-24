const DEFAULT_BASE_URL = 'https://yourimageshare.com/api';
const SDK_VERSION = '1.0.3';
/** Node's default `fetch` User-Agent is the bare string "node", which yourimageshare.com's
 *  bot-blocklist treats as a scanner and 403s. Identify the SDK explicitly instead. Only set
 *  in non-browser environments (`window` is absent) - browsers control their own UA header. */
const isBrowser = typeof window !== 'undefined';

export interface YourImageShareOptions {
  /** Your API key, from the "API" tab at https://yourimageshare.com/my-account */
  apiKey: string;
  /** Override the base URL (mainly for testing). Defaults to https://yourimageshare.com/api */
  baseUrl?: string;
}

export interface UploadOptions {
  /** Auto-delete this upload after N seconds (60 to 2,592,000 = 30 days). Omit for a permanent upload. */
  expiresIn?: number;
  /** Filename to send when `file` is a Buffer/Uint8Array/ArrayBuffer rather than a File/Blob that already has one. */
  filename?: string;
}

export type UploadType = 'image' | 'video';

export interface UploadResult {
  id: string;
  type: UploadType;
  path: string;
  src: string;
  direct: string;
  expires_at: string | null;
}

export interface ListedUpload {
  id: string;
  type: UploadType;
  title: string | null;
  path: string;
  src: string;
  direct: string;
  expires_at: string | null;
  created_at: string;
}

export interface ListMeta {
  current_page: number;
  last_page: number;
  total: number;
}

export interface ListResult {
  data: ListedUpload[];
  meta: ListMeta;
}

/** Thrown for any non-2xx response or `{"type":"error"}` payload. `status` is the HTTP status code. */
export class YourImageShareError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = 'YourImageShareError';
    this.status = status;
  }
}

export class YourImageShare {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(options: YourImageShareOptions) {
    if (!options || !options.apiKey) {
      throw new Error('YourImageShare: `apiKey` is required.');
    }
    this.apiKey = options.apiKey;
    this.baseUrl = (options.baseUrl ?? DEFAULT_BASE_URL).replace(/\/+$/, '');
  }

  private headers(): HeadersInit {
    const headers: Record<string, string> = { 'X-API-Key': this.apiKey };
    if (!isBrowser) {
      headers['User-Agent'] = `yourimageshare-js/${SDK_VERSION}`;
    }
    return headers;
  }

  private async parseJson<T>(res: Response): Promise<T> {
    let body: any = null;
    try {
      body = await res.json();
    } catch {
      throw new YourImageShareError(`Unexpected non-JSON response (HTTP ${res.status})`, res.status);
    }
    if (!res.ok || body?.type === 'error') {
      const message = typeof body?.errors === 'string' ? body.errors : `Request failed (HTTP ${res.status})`;
      throw new YourImageShareError(message, res.status);
    }
    return body as T;
  }

  /**
   * Upload a file. `file` accepts a browser File/Blob, or a raw Buffer/Uint8Array/ArrayBuffer
   * (in which case pass `options.filename` so the server sees a real extension).
   */
  async upload(file: Blob | ArrayBuffer | Uint8Array, options: UploadOptions = {}): Promise<UploadResult> {
    const blob = file instanceof Blob ? file : new Blob([file as BlobPart]);
    const form = new FormData();
    form.append('uploads', blob, options.filename ?? 'upload');
    if (options.expiresIn !== undefined) {
      form.append('expires_in', String(options.expiresIn));
    }

    const res = await fetch(this.baseUrl, {
      method: 'POST',
      headers: this.headers(),
      body: form,
    });
    const body = await this.parseJson<{ data: UploadResult }>(res);
    return body.data;
  }

  /** List your uploads, newest first. Paginated 50 per page. */
  async list(page = 1): Promise<ListResult> {
    const url = new URL(this.baseUrl);
    if (page > 1) {
      url.searchParams.set('page', String(page));
    }
    const res = await fetch(url, { headers: this.headers() });
    return this.parseJson<ListResult>(res);
  }

  /** Delete one of your uploads by id. */
  async delete(id: string): Promise<void> {
    const res = await fetch(`${this.baseUrl}/${encodeURIComponent(id)}`, {
      method: 'DELETE',
      headers: this.headers(),
    });
    await this.parseJson<{ msg: string }>(res);
  }
}

export default YourImageShare;
