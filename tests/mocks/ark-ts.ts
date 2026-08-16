/**
 * @kit.ArkTS (util) mock — 复用 Node 全局 TextEncoder，并补齐鸿蒙专有的
 * encodeIntoUint8Array 方法。
 */

class TextEncoderMock {
  private inner: TextEncoder;

  constructor() {
    this.inner = new (globalThis as Record<string, any>).TextEncoder();
  }

  encode(input?: string): Uint8Array {
    return this.inner.encode(input);
  }

  encodeIntoUint8Array(input: string, dest: Uint8Array): { read: number; written: number } {
    return this.inner.encodeInto(input, dest);
  }
}

export const util = {
  TextEncoder: TextEncoderMock
};
