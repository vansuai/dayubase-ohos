/**
 * @kit.NetworkKit (http) mock。
 * 记录所有请求，测试通过 httpCalls 断言 URL / header / body；
 * 通过 setNextResponse / setNextError 控制响应。
 */

export interface MockHttpRequest {
  url: string;
  options: Record<string, any>;
}

export const httpCalls: MockHttpRequest[] = [];

let nextResult: string = '{}';
let nextCode: number = 200;
let nextError: Error | null = null;

export function resetHttpCalls(): void {
  httpCalls.length = 0;
  nextResult = '{}';
  nextCode = 200;
  nextError = null;
}

export function setNextResponse(result: string, code: number): void {
  nextResult = result;
  nextCode = code;
  nextError = null;
}

export function setNextError(err: Error): void {
  nextError = err;
}

export const http = {
  createHttp: () => {
    const instance = {
      request: async (url: string, options: Record<string, any>) => {
        if (nextError) {
          throw nextError;
        }
        httpCalls.push({ url, options });
        return {
          result: nextResult,
          responseCode: nextCode
        };
      },
      destroy: () => {
        // no-op
      }
    };
    return instance;
  },
  HttpDataType: {
    STRING: 0
  },
  // 与鸿蒙真实枚举值保持一致：OPTIONS=0 GET=1 HEAD=2 POST=3 PUT=4 DELETE=5 TRACE=6 CONNECT=7
  RequestMethod: {
    OPTIONS: 0,
    GET: 1,
    HEAD: 2,
    POST: 3,
    PUT: 4,
    DELETE: 5,
    TRACE: 6,
    CONNECT: 7
  }
};
