import { AppModule, AppPageParams, ClientLike } from '../model/Types';

/**
 * 应用管理模块实现。
 */
class AppModuleImpl implements AppModule {
  private client: ClientLike;

  constructor(client: ClientLike) {
    this.client = client;
  }

  async page(params?: AppPageParams): Promise<Object> {
    const p: AppPageParams = params === undefined ? ({} as AppPageParams) : params;
    const current: number = p.current === undefined ? 1 : p.current;
    const pageSize: number = p.pageSize === undefined ? 10 : p.pageSize;
    const data: Record<string, Object> = {};
    data['current'] = current;
    data['pageSize'] = pageSize;
    if (p.projectId !== undefined) {
      data['projectId'] = p.projectId;
    }
    if (p.name !== undefined) {
      data['name'] = p.name;
    }
    return this.client.request('/admin/application/page', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  async create(data: Record<string, Object>): Promise<Object> {
    return this.client.request('/admin/application', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  async overview(appId: string): Promise<Object> {
    return this.client.request(`/admin/application/overview?id=${appId}`, {
      method: 'GET'
    });
  }

  async update(appId: string, data: Record<string, Object>): Promise<Object> {
    return this.client.request(`/admin/application/update/${appId}`, {
      method: 'PATCH',
      body: JSON.stringify(data)
    });
  }

  async delete(appId: string): Promise<Object> {
    return this.client.request(`/admin/application/${appId}`, {
      method: 'DELETE'
    });
  }

  async recycle(appId: string, data: Record<string, Object>): Promise<Object> {
    return this.client.request(`/admin/application/recycle/${appId}`, {
      method: 'PATCH',
      body: JSON.stringify(data)
    });
  }

  async copy(appId: string): Promise<Object> {
    return this.client.request(`/admin/application/copy/${appId}`, {
      method: 'POST'
    });
  }

  async export(appId: string): Promise<Object> {
    return this.client.request(`/admin/application/import/${appId}`, {
      method: 'POST'
    });
  }

  async import(data: Record<string, Object>): Promise<Object> {
    return this.client.request('/admin/application/save/file', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  async getLoginInfo(appId: string, relevanceId: string): Promise<Object> {
    const query: Record<string, Object> = {};
    query['id'] = appId;
    query['relevanceId'] = relevanceId;
    return this.client.request('/admin/application/login-info', {
      method: 'GET',
      params: query
    });
  }
}

/**
 * 创建应用管理模块。
 */
export function appModule(client: ClientLike): AppModule {
  return new AppModuleImpl(client);
}
