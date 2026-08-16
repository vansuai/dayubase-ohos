import { beforeEach, describe, expect, it } from 'vitest';
import { createClient } from '../library/src/main/ets/client/DayuBaseClient.ets';
import { httpCalls, resetHttpCalls } from './mocks/network-kit';
import { resetStore } from './mocks/ark-data';

const fakeContext = {} as object;

function makeClient() {
  return createClient({ baseUrl: 'https://api.test', context: fakeContext });
}

beforeEach(() => {
  resetHttpCalls();
  resetStore();
});

describe('project 模块（与 JS SDK 端点一致）', () => {
  it('create POST /admin/project', async () => {
    const data = { projectName: '我的项目', description: 'd' } as Record<string, Object>;
    await makeClient().project.create(data);
    expect(httpCalls[0].url).toBe('https://api.test/admin/project');
    expect(JSON.parse(httpCalls[0].options.extraData as string)).toEqual(data);
  });

  it('overview GET /admin/project/overview?id=', async () => {
    await makeClient().project.overview('pid-1');
    expect(httpCalls[0].url).toBe('https://api.test/admin/project/overview?id=pid-1');
  });

  it('update PATCH /admin/project/update/{id}', async () => {
    const data = { projectName: '新名字' } as Record<string, Object>;
    await makeClient().project.update('pid-1', data);
    expect(httpCalls[0].url).toBe('https://api.test/admin/project/update/pid-1');
    expect(httpCalls[0].options.method).toBe('PATCH'); // @ohos.net.http 无 PATCH 枚举，以字符串传递
  });

  it('delete DELETE /admin/project/{id}', async () => {
    await makeClient().project.delete('pid-1');
    expect(httpCalls[0].url).toBe('https://api.test/admin/project/pid-1');
    expect(httpCalls[0].options.method).toBe(5); // DELETE
  });
});

describe('app 模块（与 JS SDK 端点一致）', () => {
  it('page POST /admin/application/page 携带 projectId', async () => {
    await makeClient().app.page({ projectId: 'pid-1', current: 1, pageSize: 10 });
    expect(httpCalls[0].url).toBe('https://api.test/admin/application/page');
    expect(JSON.parse(httpCalls[0].options.extraData as string)).toEqual({
      current: 1,
      pageSize: 10,
      projectId: 'pid-1'
    });
  });

  it('overview GET /admin/application/overview?id=', async () => {
    await makeClient().app.overview('aid-1');
    expect(httpCalls[0].url).toBe('https://api.test/admin/application/overview?id=aid-1');
  });

  it('recycle PATCH /admin/application/recycle/{id}', async () => {
    const data = { appId: 'aid-1' } as Record<string, Object>;
    await makeClient().app.recycle('aid-1', data);
    expect(httpCalls[0].url).toBe('https://api.test/admin/application/recycle/aid-1');
    expect(httpCalls[0].options.method).toBe('PATCH'); // @ohos.net.http 无 PATCH 枚举，以字符串传递
  });

  it('export POST /admin/application/import/{id}', async () => {
    await makeClient().app.export('aid-1');
    expect(httpCalls[0].url).toBe('https://api.test/admin/application/import/aid-1');
  });

  it('getLoginInfo GET /admin/application/login-info?id=&relevanceId=', async () => {
    await makeClient().app.getLoginInfo('aid-1', '123');
    expect(httpCalls[0].url).toBe('https://api.test/admin/application/login-info?id=aid-1&relevanceId=123');
  });
});
