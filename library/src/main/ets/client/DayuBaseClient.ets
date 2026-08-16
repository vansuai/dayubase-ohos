import { OhosPlatform } from '../platform/OhosPlatform';
import { UrlUtil } from '../util/UrlUtil';
import { BaaSFacade, ClientLike, CreateClientConfig, PlatformLike, RequestOptions } from '../model/Types';
import { authModule } from '../modules/AuthModule';
import { dbModule } from '../modules/DbModule';
import { apiModule } from '../modules/ApiModule';
import { projectModule } from '../modules/ProjectModule';
import { appModule } from '../modules/AppModule';
import { fileModule } from '../modules/FileModule';
import { AuthModule, ApiModule, AppModule, DbModule, FileModule, ProjectModule } from '../model/Types';

/** token 存储键，与 JS SDK 保持一致 */
const TOKEN_KEY: string = 'baas_token';

/**
 * DayuBase BaaS 核心客户端。
 */
export class BaaSClient implements ClientLike {
  baseUrl: string;
  apiKey: string | null;
  appId: string | null;
  token: string | null;
  platform: PlatformLike;

  constructor(config: CreateClientConfig) {
    this.baseUrl = config.baseUrl;
    this.apiKey = config.apiKey === undefined ? null : config.apiKey;
    this.appId = config.appId === undefined ? null : config.appId;
    this.platform = new OhosPlatform(config.context);
    this.token = this.platform.storage.get(TOKEN_KEY);
  }

  /**
   * 设置认证 token（null 清除），同步写入本地存储。
   */
  setToken(token: string | null): void {
    this.token = token;
    if (token) {
      this.platform.storage.set(TOKEN_KEY, token);
    } else {
      this.platform.storage.remove(TOKEN_KEY);
    }
  }

  /**
   * 统一请求入口：拼接 URL 与查询参数、组装请求头、发起请求并解析 JSON。
   */
  request(path: string, options?: RequestOptions): Promise<Object> {
    const opts: RequestOptions = options === undefined ? ({} as RequestOptions) : options;
    let url: string = `${this.baseUrl}${path}`;
    const qs: string = UrlUtil.serializeQuery(opts.params);
    if (qs !== '') {
      url += url.includes('?') ? '&' : '?';
      url += qs;
    }

    const headers: Record<string, string> = {};
    headers['Content-Type'] = 'application/json';
    if (this.appId !== null) {
      headers['APP_ID'] = this.appId;
    }
    if (this.apiKey !== null) {
      headers['CODE_FLYING'] = this.apiKey;
    }
    if (this.token !== null) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }
    if (opts.headers !== undefined) {
      const keys: string[] = Object.keys(opts.headers);
      for (let i = 0; i < keys.length; i++) {
        headers[keys[i]] = opts.headers[keys[i]];
      }
    }

    return this.platform.http.request(url, {
      method: opts.method,
      headers: headers,
      body: opts.body
    }).then((response) => response.json());
  }
}

/**
 * createClient 返回的门面实现。
 */
class BaaSFacadeImpl implements BaaSFacade {
  private client: BaaSClient;
  auth: AuthModule;
  db: DbModule;
  api: ApiModule;
  project: ProjectModule;
  app: AppModule;
  file: FileModule;

  constructor(client: BaaSClient) {
    this.client = client;
    this.auth = authModule(client);
    this.db = dbModule(client);
    this.api = apiModule(client);
    this.project = projectModule(client);
    this.app = appModule(client);
    this.file = fileModule(client);
  }

  setToken(token: string | null): void {
    this.client.setToken(token);
  }
}

/**
 * 创建 DayuBase 客户端门面。
 *
 * 示例：
 * ```
 * import { createClient } from 'dayubase-ohos';
 * const client = createClient({
 *   baseUrl: 'https://api.example.com',
 *   appId: 'your-app-id',
 *   apiKey: 'your-api-key',
 *   context: getContext(this)
 * });
 * ```
 */
export function createClient(config: CreateClientConfig): BaaSFacade {
  const client: BaaSClient = new BaaSClient(config);
  return new BaaSFacadeImpl(client);
}
