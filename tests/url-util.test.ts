import { describe, expect, it } from 'vitest';
import { UrlUtil } from '../library/src/main/ets/util/UrlUtil.ets';

describe('UrlUtil.serializeQuery', () => {
  it('序列化简单参数', () => {
    const params = { a: '1', b: 'x y' } as Record<string, Object>;
    expect(UrlUtil.serializeQuery(params)).toBe('a=1&b=x%20y');
  });

  it('过滤 undefined 与 null', () => {
    const params = { a: '1', b: undefined, c: null } as Record<string, Object>;
    expect(UrlUtil.serializeQuery(params)).toBe('a=1');
  });

  it('数字参数转字符串', () => {
    const params = { current: 1, pageSize: 20 } as Record<string, Object>;
    expect(UrlUtil.serializeQuery(params)).toBe('current=1&pageSize=20');
  });

  it('中文与特殊字符编码', () => {
    const params = { keyword: '你好', q: 'a&b=1' } as Record<string, Object>;
    expect(UrlUtil.serializeQuery(params)).toBe('keyword=%E4%BD%A0%E5%A5%BD&q=a%26b%3D1');
  });

  it('undefined 入参返回空串', () => {
    expect(UrlUtil.serializeQuery(undefined)).toBe('');
  });

  it('空对象返回空串', () => {
    const params = {} as Record<string, Object>;
    expect(UrlUtil.serializeQuery(params)).toBe('');
  });
});
