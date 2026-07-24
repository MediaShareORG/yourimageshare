export const DEFAULT_BASE_URL = 'https://yourimageshare.com/api';
const SDK_VERSION = '1.0.2';

export interface UploadResult {
  id: string;
  type: 'image' | 'video';
  path: string;
  src: string;
  direct: string;
  expires_at: string | null;
}

export interface ListedUpload {
  id: string;
  type: 'image' | 'video';
  title: string | null;
  path: string;
  src: string;
  direct: string;
  expires_at: string | null;
  created_at: string;
}

export interface ListResult {
  data: ListedUpload[];
  meta: { current_page: number; last_page: number; total: number };
}

export class YourImageShareApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = 'YourImageShareApiError';
    this.status = status;
  }
}

/** Minimal internal client, kept self-contained rather than depending on the
 *  separate `yourimageshare` npm package (not published yet, and this server
 *  should build/publish independently of that package's release timeline). */
export class YourImageShareClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(apiKey: string, baseUrl: string) {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl.replace(/\/+$/, '');
  }

  private headers(): HeadersInit {
    return {
      'X-API-Key': this.apiKey,
      'User-Agent': `yourimageshare-mcp/${SDK_VERSION}`,
    };
  }

  private async parse<T>(res: Response): Promise<T> {
    let body: any;
    try {
      body = await res.json();
    } catch {
      throw new YourImageShareApiError(`Unexpected non-JSON response (HTTP ${res.status})`, res.status);
    }
    if (!res.ok || body?.type === 'error') {
      const message = typeof body?.errors === 'string' ? body.errors : `Request failed (HTTP ${res.status})`;
      throw new YourImageShareApiError(message, res.status);
    }
    return body as T;
  }

  async upload(blob: Blob, filename: string, expiresIn?: number): Promise<UploadResult> {
    const form = new FormData();
    form.append('uploads', blob, filename);
    if (expiresIn !== undefined) {
      form.append('expires_in', String(expiresIn));
    }
    const res = await fetch(this.baseUrl, { method: 'POST', headers: this.headers(), body: form });
    const body = await this.parse<{ data: UploadResult }>(res);
    return body.data;
  }

  async list(page = 1): Promise<ListResult> {
    const url = new URL(this.baseUrl);
    if (page > 1) url.searchParams.set('page', String(page));
    const res = await fetch(url, { headers: this.headers() });
    return this.parse<ListResult>(res);
  }

  async delete(id: string): Promise<void> {
    const res = await fetch(`${this.baseUrl}/${encodeURIComponent(id)}`, {
      method: 'DELETE',
      headers: this.headers(),
    });
    await this.parse<{ msg: string }>(res);
  }
}
