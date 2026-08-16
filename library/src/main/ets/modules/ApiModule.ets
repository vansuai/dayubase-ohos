import { ApiBuilderLike, ApiModule, ClientLike } from '../model/Types';

/**
 * 自定义 API 链式构建器：/api/{apiName}
 */
class ApiBuilder implements ApiBuilderLike {
  private client: ClientLike;
  private apiName: string;
  private _params: Record<string, Object> = {};
  private _headers: Record<string, string> = {};

  constructor(client: ClientLike, apiName: string) {
    this.client = client;
    this.apiName = apiName;
  }

  param(key: string, value: Object): ApiBuilderLike {
    this._params[key] = value;
    return this;
  }

  params(obj: Record<string, Object>): ApiBuilderLike {
    const keys: string[] = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      this._params[keys[i]] = obj[keys[i]];
    }
    return this;
  }

  header(key: string, value: string): ApiBuilderLike {
    this._headers[key] = value;
    return this;
  }

  headers(obj: Record<string, string>): ApiBuilderLike {
    const keys: string[] = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      this._headers[keys[i]] = obj[keys[i]];
    }
    return this;
  }

  execute(): Promise<Object> {
    const body: string = JSON.stringify(this._params);
    const url: string = `/api/${this.apiName}`;
    return this.client.request(url, {
      method: 'POST',
      headers: this._headers,
      body: body
    });
  }
}

/**
 * API 模块实现：调用后端自定义 API。
 */
class ApiModuleImpl implements ApiModule {
  private client: ClientLike;

  constructor(client: ClientLike) {
    this.client = client;
  }

  call(apiName: string): ApiBuilderLike {
    return new ApiBuilder(this.client, apiName);
  }
}

/**
 * 创建 API 模块。
 */
export function apiModule(client: ClientLike): ApiModule {
  return new ApiModuleImpl(client);
}
