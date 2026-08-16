/**
 * @kit.ArkData (preferences) mock — 内存 KV 存储。
 */

const store = new Map<string, string>();

export function resetStore(): void {
  store.clear();
}

export function dumpStore(): Record<string, string> {
  const out: Record<string, string> = {};
  store.forEach((v, k) => {
    out[k] = v;
  });
  return out;
}

export const preferences = {
  getPreferencesSync: (context: object, options: { name: string }) => ({
    getSync: (key: string, def: string): string => (store.has(key) ? (store.get(key) as string) : def),
    putSync: (key: string, value: string): void => {
      store.set(key, value);
    },
    deleteSync: (key: string): void => {
      store.delete(key);
    },
    flushSync: (): void => {
      // no-op
    },
    flush: (): Promise<void> => Promise.resolve()
  })
};
