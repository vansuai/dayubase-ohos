import { defineConfig } from 'vitest/config';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/**
 * 让 vitest 直接运行鸿蒙 SDK 的 .ets 源码：
 * 1. transform 插件把 .ets 当作 TS 编译（ArkTS 是 TS 子集，esbuild 可编译）；
 * 2. alias 把 @kit.* 模块替换为 Node 侧 mock，从而在无鸿蒙运行时下测试 SDK 逻辑。
 */
export default defineConfig({
  plugins: [
    {
      name: 'ets-transform',
      enforce: 'pre',
      async transform(code, id) {
        if (id.endsWith('.ets')) {
          const esbuild = await import('esbuild');
          const result = await esbuild.transform(code, { loader: 'ts', target: 'es2020' });
          return { code: result.code, map: null };
        }
        return null;
      }
    }
  ],
  resolve: {
    extensions: ['.mjs', '.js', '.mts', '.ts', '.jsx', '.tsx', '.json', '.ets'],
    alias: {
      '@kit.AbilityKit': path.resolve(__dirname, 'mocks/ability-kit.ts'),
      '@kit.NetworkKit': path.resolve(__dirname, 'mocks/network-kit.ts'),
      '@kit.ArkData': path.resolve(__dirname, 'mocks/ark-data.ts'),
      '@kit.CoreFileKit': path.resolve(__dirname, 'mocks/core-file-kit.ts'),
      '@kit.ArkTS': path.resolve(__dirname, 'mocks/ark-ts.ts')
    }
  },
  test: {
    root: path.resolve(__dirname, '..'),
    include: ['tests/**/*.test.ts'],
    environment: 'node'
  }
});
