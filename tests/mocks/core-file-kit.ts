/**
 * @kit.CoreFileKit (fileIo) mock — 返回空文件内容。
 */

export const fileIo = {
  statSync: (uri: string) => ({
    size: 0
  }),
  openSync: (uri: string, mode?: number) => ({
    fd: -1
  }),
  readSync: (fd: number, buffer: ArrayBuffer): number => 0,
  closeSync: (file: object): void => {
    // no-op
  },
  OpenMode: {
    READ_ONLY: 0
  }
};
