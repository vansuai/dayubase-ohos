import { beforeEach, describe, expect, it } from 'vitest';
import { createClient } from '../library/src/main/ets/client/DayuBaseClient.ets';
import { httpCalls, resetHttpCalls, setNextResponse } from './mocks/network-kit';
import { resetStore } from './mocks/ark-data';

const fakeContext = {} as object;

beforeEach(() => {
  resetHttpCalls();
  resetStore();
  setNextResponse('{"code":0,"data":{"url":"/files/a.jpg","fileName":"a.jpg"},"message":"ok","success":true}', 200);
});

describe('file 模块', () => {
  it('upload 发送 multipart POST 到 /common/upload', async () => {
    const client = createClient({
      baseUrl: 'https://api.test',
      appId: 'app1',
      apiKey: 'key1',
      context: fakeContext
    });
    client.setToken('tok-1');
    const res = await client.file.upload('/data/storage/el2/base/files/a.jpg');
    expect(httpCalls).toHaveLength(1);
    const call = httpCalls[0];
    expect(call.url).toBe('https://api.test/common/upload');
    expect(call.options.method).toBe(3); // POST
    expect(call.options.header['Content-Type']).toContain('multipart/form-data; boundary=');
    expect(call.options.header['APP_ID']).toBe('app1');
    expect(call.options.header['CODE_FLYING']).toBe('key1');
    expect(call.options.header['Authorization']).toBe('Bearer tok-1');
    expect(call.options.extraData).toBeInstanceOf(ArrayBuffer);
    // 返回解析后的 JSON
    const data = (res as Record<string, Object>)['data'] as Record<string, Object>;
    expect(data['url']).toBe('/files/a.jpg');
  });

  it('upload 支持自定义 filename / fileType / headers', async () => {
    const client = createClient({ baseUrl: 'https://api.test', context: fakeContext });
    await client.file.upload('https://cdn.example.com/logo.png', {
      filename: 'logo.png',
      fileType: 'image/png',
      headers: { 'X-Source': 'picker' }
    });
    expect(httpCalls[0].options.header['X-Source']).toBe('picker');
    expect(httpCalls[0].options.header['Content-Type']).toContain('boundary=');
  });
});
