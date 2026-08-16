import { beforeEach, describe, expect, it } from 'vitest';
import { createClient } from '../library/src/main/ets/client/DayuBaseClient.ets';
import { http, httpCalls, resetHttpCalls } from './mocks/network-kit';
import { resetStore } from './mocks/ark-data';

const fakeContext = {} as object;

beforeEach(() => {
  resetHttpCalls();
  resetStore();
});

describe('api 模块', () => {
  it('call + param 发送 POST /api/{name}', async () => {
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    await client.api.call('sendEmail').param('to', 'a@b.com').param('subject', 'hi').execute();
    expect(httpCalls[0].url).toBe('https://api.test/api/sendEmail');
    expect(httpCalls[0].options.method).toBe(http.RequestMethod.POST);
    expect(JSON.parse(httpCalls[0].options.extraData as string)).toEqual({ to: 'a@b.com', subject: 'hi' });
  });

  it('params 批量设置', async () => {
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    const p = { k1: 'v1', k2: 2 } as Record<string, Object>;
    await client.api.call('myApi').params(p).execute();
    expect(JSON.parse(httpCalls[0].options.extraData as string)).toEqual({ k1: 'v1', k2: 2 });
  });

  it('header/headers 自定义请求头', async () => {
    const client = createClient({ baseUrl: 'https://api.test', appId: 'app1', context: fakeContext });
    await client.api
      .call('myApi')
      .header('X-Custom', 'v1')
      .headers({ 'X-Another': 'v2' })
      .param('data', 'x')
      .execute();
    expect(httpCalls[0].options.header['X-Custom']).toBe('v1');
    expect(httpCalls[0].options.header['X-Another']).toBe('v2');
    // 默认头仍存在
    expect(httpCalls[0].options.header['APP_ID']).toBe('app1');
    expect(httpCalls[0].options.header['Content-Type']).toBe('application/json');
  });
});
