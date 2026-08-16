import { beforeEach, describe, expect, it } from 'vitest';
import { createClient } from '../library/src/main/ets/client/DayuBaseClient.ets';
import { http, httpCalls, resetHttpCalls, setNextError, setNextResponse } from './mocks/network-kit';
import { resetStore } from './mocks/ark-data';

const fakeContext = {} as object;

beforeEach(() => {
  resetHttpCalls();
  resetStore();
  setNextResponse('{"code":0,"data":{},"message":"ok","success":true}', 200);
});

describe('createClient / request', () => {
  it('组装 APP_ID / CODE_FLYING / Content-Type 请求头', async () => {
    const client = createClient({
      baseUrl: 'https://api.test',
      appId: 'app1',
      apiKey: 'key1',
      context: fakeContext
    });
    await client.auth.getUser();
    expect(httpCalls).toHaveLength(1);
    expect(httpCalls[0].url).toBe('https://api.test/getUserInfo');
    expect(httpCalls[0].options.header['APP_ID']).toBe('app1');
    expect(httpCalls[0].options.header['CODE_FLYING']).toBe('key1');
    expect(httpCalls[0].options.header['Content-Type']).toBe('application/json');
    expect(httpCalls[0].options.header['Authorization']).toBeUndefined();
    expect(httpCalls[0].options.method).toBe(http.RequestMethod.GET);
  });

  it('setToken 后带 Authorization，且新客户端从存储恢复 token', async () => {
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    client.setToken('tok-123');

    const client2 = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    await client2.auth.getUser();
    expect(httpCalls[0].options.header['Authorization']).toBe('Bearer tok-123');
  });

  it('setToken(null) 清除 token', async () => {
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    client.setToken('tok-123');
    client.setToken(null);
    await client.auth.getUser();
    expect(httpCalls[0].options.header['Authorization']).toBeUndefined();
  });

  it('params 序列化为查询字符串', async () => {
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    await client.project.page({ current: 2, pageSize: 20 });
    expect(httpCalls[0].url).toBe('https://api.test/admin/project/page?current=2&pageSize=20');
  });

  it('网络失败抛出 DayuBaseError', async () => {
    setNextError(new Error('connection refused'));
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    await expect(client.auth.getUser()).rejects.toThrow('网络请求失败');
  });

  it('非 2xx 状态码仍返回 JSON（由业务层按 success 判断）', async () => {
    setNextResponse('{"code":401,"data":null,"message":"未登录","success":false}', 401);
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    const res = await client.auth.getUser();
    expect((res as Record<string, Object>)['success']).toBe(false);
  });
});
