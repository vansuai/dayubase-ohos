/**
 * 纯逻辑工具：查询字符串序列化。
 * 不依赖任何鸿蒙 API，可直接在 Node 环境单测。
 */
export class UrlUtil {

  /**
   * 将对象序列化为 query string，过滤 undefined/null 值。
   * 与 JS SDK 的序列化逻辑保持一致。
   */
  static serializeQuery(params: Record<string, Object> | undefined): string {
    if (params === undefined) {
      return '';
    }
    const keys: string[] = Object.keys(params);
    const parts: string[] = [];
    for (let i = 0; i < keys.length; i++) {
      const key: string = keys[i];
      const value: Object | undefined = params[key];
      if (value === undefined || value === null) {
        continue;
      }
      parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);
    }
    return parts.join('&');
  }
}
