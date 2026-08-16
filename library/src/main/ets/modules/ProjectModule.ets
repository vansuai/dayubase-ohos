import { ClientLike, ProjectModule, ProjectPageParams } from '../model/Types';

/**
 * 项目管理模块实现。
 */
class ProjectModuleImpl implements ProjectModule {
  private client: ClientLike;

  constructor(client: ClientLike) {
    this.client = client;
  }

  async page(params?: ProjectPageParams): Promise<Object> {
    const p: ProjectPageParams = params === undefined ? {} : params;
    const current: number = p.current === undefined ? 1 : p.current;
    const pageSize: number = p.pageSize === undefined ? 10 : p.pageSize;
    const query: Record<string, Object> = {};
    query['current'] = current;
    query['pageSize'] = pageSize;
    if (p.projectName !== undefined) {
      query['projectName'] = p.projectName;
    }
    return this.client.request('/admin/project/page', {
      method: 'GET',
      params: query
    });
  }

  async create(data: Record<string, Object>): Promise<Object> {
    return this.client.request('/admin/project', {
      method: 'POST',
      body: JSON.stringify(data)
    });
  }

  async overview(projectId: string): Promise<Object> {
    const query: Record<string, Object> = {};
    query['id'] = projectId;
    return this.client.request('/admin/project/overview', {
      method: 'GET',
      params: query
    });
  }

  async update(projectId: string, data: Record<string, Object>): Promise<Object> {
    return this.client.request(`/admin/project/update/${projectId}`, {
      method: 'PATCH',
      body: JSON.stringify(data)
    });
  }

  async delete(projectId: string): Promise<Object> {
    return this.client.request(`/admin/project/${projectId}`, {
      method: 'DELETE'
    });
  }
}

/**
 * 创建项目管理模块。
 */
export function projectModule(client: ClientLike): ProjectModule {
  return new ProjectModuleImpl(client);
}
