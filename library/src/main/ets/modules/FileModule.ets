import { ClientLike, FileModule, UploadOptions } from '../model/Types';

/**
 * 文件模块实现：上传文件到后端 /common/upload。
 */
class FileModuleImpl implements FileModule {
  private client: ClientLike;

  constructor(client: ClientLike) {
    this.client = client;
  }

  async upload(uri: string, options?: UploadOptions): Promise<Object> {
    const opts: UploadOptions = options === undefined ? ({} as UploadOptions) : options;
    const headers: Record<string, string> = {};
    if (this.client.appId !== null) {
      headers['APP_ID'] = this.client.appId;
    }
    if (this.client.apiKey !== null) {
      headers['CODE_FLYING'] = this.client.apiKey;
    }
    if (this.client.token !== null) {
      headers['Authorization'] = `Bearer ${this.client.token}`;
    }
    if (opts.headers !== undefined) {
      const keys: string[] = Object.keys(opts.headers);
      for (let i = 0; i < keys.length; i++) {
        headers[keys[i]] = opts.headers[keys[i]];
      }
    }
    const url: string = `${this.client.baseUrl}/common/upload`;
    const response = await this.client.platform.http.uploadFile(url, {
      uri: uri,
      headers: headers,
      filename: opts.filename,
      fileType: opts.fileType
    });
    return response.json();
  }
}

/**
 * 创建文件模块。
 */
export function fileModule(client: ClientLike): FileModule {
  return new FileModuleImpl(client);
}
