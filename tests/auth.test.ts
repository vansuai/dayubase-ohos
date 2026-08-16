import { beforeEach, describe, expect, it } from 'vitest';
import { createClient } from '../library/src/main/ets/client/DayuBaseClient.ets';
import { httpCalls, resetHttpCalls, setNextResponse } from './mocks/network-kit';
import { resetStore } from './mocks/ark-data';

const fakeContext = {} as object;

function makeClient() {
  return createClient({ baseUrl: 'https://api.test', context: fakeContext });
}

beforeEach(() => {
  resetHttpCalls();
  resetStore();
});

describe('auth 模块', () => {
  it('手机号登录：POST /login/passwd 并保存 token', async () => {
    setNextResponse('{"code":0,"data":"token-abc","message":"ok","success":true}', 200);
    const client = makeClient();
    await client.auth.login({ phone: '13800138000', password: 'pass123' });
    expect(httpCalls[0].url).toBe('https://api.test/login/passwd');
    const body = JSON.parse(httpCalls[0].options.extraData as string);
    expect(body).toEqual({ phone: '13800138000', password: 'pass123' });

    // token 已保存：后续请求带 Authorization
    await client.auth.getUser();
    expect(httpCalls[1].options.header['Authorization']).toBe('Bearer token-abc');
  });

  it('user_name / email 也映射到 phone 字段（与 JS SDK 一致）', async () => {
    setNextResponse('{"code":0,"data":"t1","message":"ok","success":true}', 200);
    await makeClient().auth.login({ user_name: 'admin', password: 'x' });
    const body = JSON.parse(httpCalls[0].options.extraData as string);
    expect(body.phone).toBe('admin');
  });

  it('缺少账号抛错', async () => {
    await expect(makeClient().auth.login({ password: 'x' })).rejects.toThrow('必须提供');
  });

  it('缺少密码抛错', async () => {
    await expect(makeClient().auth.login({ phone: '13800138000', password: '' })).rejects.toThrow('必须提供 password');
  });

  it('register 提交注册数据', async () => {
    const data = { user_name: 'newuser', password: 'p' } as Record<string, Object>;
    await makeClient().auth.register(data);
    expect(httpCalls[0].url).toBe('https://api.test/login/register');
    expect(JSON.parse(httpCalls[0].options.extraData as string)).toEqual({ user_name: 'newuser', password: 'p' });
  });

  it('logout 清除 token 并请求 /logout', async () => {
    setNextResponse('{"code":0,"data":"t1","message":"ok","success":true}', 200);
    const client = makeClient();
    await client.auth.login({ phone: '13800138000', password: 'x' });
    await client.auth.logout();
    expect(httpCalls[1].url).toBe('https://api.test/logout');
    expect(httpCalls[1].options.header['Authorization']).toBeUndefined();
  });

  it('loginByWeapp 携带 code 与 relevanceTable 并保存 token', async () => {
    setNextResponse('{"code":0,"data":"wx-token","message":"ok","success":true}', 200);
    await makeClient().auth.loginByWeapp('wx-code', 'wechat_users');
    const body = JSON.parse(httpCalls[0].options.extraData as string);
    expect(body).toEqual({ code: 'wx-code', relevanceTable: 'wechat_users' });
    expect(httpCalls[0].url).toBe('https://api.test/login/weapp');
  });

  it('loginByWeapp 缺 code 抛错', async () => {
    await expect(makeClient().auth.loginByWeapp('')).rejects.toThrow('必须提供 code');
  });
});
