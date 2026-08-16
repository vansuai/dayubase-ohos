import { beforeEach, describe, expect, it } from 'vitest';
import { createClient } from '../library/src/main/ets/client/DayuBaseClient.ets';
import { http, httpCalls, resetHttpCalls } from './mocks/network-kit';
import { resetStore } from './mocks/ark-data';

const fakeContext = {} as object;

function makeClient() {
  return createClient({ baseUrl: 'https://api.test', context: fakeContext });
}

function bodyOf(index: number): Record<string, any> {
  return JSON.parse(httpCalls[index].options.extraData as string);
}

beforeEach(() => {
  resetHttpCalls();
  resetStore();
});

describe('db 模块', () => {
  it('list + eq/gt 过滤条件', async () => {
    await makeClient().db.from('users').list().eq('status', 'active').gt('age', 18).execute();
    expect(httpCalls[0].url).toBe('https://api.test/api/data/invoke?table=users&method=list');
    expect(httpCalls[0].options.method).toBe(http.RequestMethod.POST);
    expect(bodyOf(0)).toEqual({ status: { eq: 'active' }, age: { gt: 18 } });
  });

  it('完整过滤操作符 in/between/like/neq/gte/lte', async () => {
    await makeClient().db
      .from('products')
      .list()
      .neq('deleted', true)
      .gte('price', 10)
      .lte('price', 100)
      .in('category', ['a', 'b'])
      .between('stock', [1, 50])
      .like('name', '手机')
      .execute();
    expect(bodyOf(0)).toEqual({
      deleted: { neq: true },
      price: { gte: 10, lte: 100 },
      category: { in: ['a', 'b'] },
      stock: { between: [1, 50] },
      name: { like: '手机' }
    });
  });

  it('排序与分页', async () => {
    await makeClient().db.from('posts').page().page(2, 30).order('created_at', 'desc').execute();
    expect(httpCalls[0].url).toBe('https://api.test/api/data/invoke?table=posts&method=page');
    expect(bodyOf(0)).toEqual({
      current: 2,
      pageSize: 30,
      order_by: [{ field: 'created_at', direction: 'desc' }]
    });
  });

  it('or 子条件（与 JS SDK 语义一致：单个 sub-builder）', async () => {
    await makeClient().db
      .from('users')
      .list()
      .eq('status', 'active')
      .or((q: any) => {
        q.eq('role', 'admin').eq('status', 'vip');
      })
      .execute();
    expect(bodyOf(0)).toEqual({
      status: { eq: 'active' },
      or: [{ role: { eq: 'admin' }, status: { eq: 'vip' } }]
    });
  });

  it('insert().values() 数据合并', async () => {
    await makeClient().db.from('users').insert().values({ name: 'John', age: 25 }).execute();
    expect(httpCalls[0].url).toBe('https://api.test/api/data/invoke?table=users&method=add');
    expect(bodyOf(0)).toEqual({ name: 'John', age: 25 });
  });

  it('update().set().eq() 条件 + 数据合并', async () => {
    await makeClient().db.from('users').update().set({ status: 'inactive' }).eq('id', 123).execute();
    expect(httpCalls[0].url).toBe('https://api.test/api/data/invoke?table=users&method=update');
    expect(bodyOf(0)).toEqual({ id: { eq: 123 }, status: 'inactive' });
  });

  it('insertBatch().values() 发送数组 body', async () => {
    const rows = [{ name: 'A' }, { name: 'B' }] as Object[];
    await makeClient().db.from('users').insertBatch().values(rows).execute();
    expect(httpCalls[0].url).toBe('https://api.test/api/data/invoke?table=users&method=addbatch');
    expect(bodyOf(0)).toEqual([{ name: 'A' }, { name: 'B' }]);
  });

  it('get/delete 使用对应 method', async () => {
    await makeClient().db.from('users').get().eq('id', 7).execute();
    expect(httpCalls[0].url).toBe('https://api.test/api/data/invoke?table=users&method=get');
    await makeClient().db.from('users').delete().eq('id', 7).execute();
    expect(httpCalls[1].url).toBe('https://api.test/api/data/invoke?table=users&method=delete');
  });
});
