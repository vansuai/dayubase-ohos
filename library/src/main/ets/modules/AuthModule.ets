import { AuthModule, ClientLike, DayuBaseResponse, LoginParams } from '../model/Types';

/**
 * 认证模块实现：登录 / 注册 / 用户信息 / 登出 / 小程序 code 登录。
 */
class AuthModuleImpl implements AuthModule {
  private client: ClientLike;

  constructor(client: ClientLike) {
    this.client = client;
  }

  async login(params: LoginParams): Promise<Object> {
    const account: string = params.user_name !== undefined ? params.user_name
      : (params.phone !== undefined ? params.phone
        : (params.email !== undefined ? params.email : ''));
    if (account === '') {
      throw new Error('必须提供 user_name、phone 或 email 之一');
    }
    if (params.password === '') {
      throw new Error('必须提供 password');
    }
    const loginBody: Record<string, Object> = {};
    loginBody['phone'] = account;
    loginBody['password'] = params.password;
    const res: Object = await this.client.request('/login/passwd', {
      method: 'POST',
      body: JSON.stringify(loginBody)
    });
    const typed: DayuBaseResponse<Object> = res as DayuBaseResponse<Object>;
    if (typed.success) {
      this.client.setToken(String(typed.data));
    }
    return res;
  }

  async register(data: Record<string, Object>): Promise<Object> {
    return this.client.request('/login/register', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  async getUser(): Promise<Object> {
    return this.client.request('/getUserInfo', {
      method: 'GET'
    });
  }

  async logout(): Promise<Object> {
    this.client.setToken(null);
    return this.client.request('/logout', {
      method: 'GET'
    });
  }

  async loginByWeapp(code: string, relevanceTable?: string): Promise<Object> {
    if (code === '') {
      throw new Error('必须提供 code');
    }
    const body: Record<string, Object> = {};
    body['code'] = code;
    if (relevanceTable !== undefined) {
      body['relevanceTable'] = relevanceTable;
    }
    const res: Object = await this.client.request('/login/weapp', {
      method: 'POST',
      body: JSON.stringify(body)
    });
    const typed: DayuBaseResponse<Object> = res as DayuBaseResponse<Object>;
    if (typed.success) {
      this.client.setToken(String(typed.data));
    }
    return res;
  }
}

/**
 * 创建认证模块。
 */
export function authModule(client: ClientLike): AuthModule {
  return new AuthModuleImpl(client);
}
