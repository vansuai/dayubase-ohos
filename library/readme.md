# DayuBase HarmonyOS SDK (dayubase-ohos)

一个简洁易用的 BaaS (Backend as a Service) HarmonyOS 三方库，基于 **ArkTS / HarmonyOS NEXT (API 12+)** 开发，与 Web/小程序端 [dayubase-js](../dayubase-js/README.md) 功能对齐。提供用户认证、数据库 CRUD、自定义 API、项目管理、应用管理和文件上传能力。

## 特性

- 🔐 **用户认证** — 登录（用户名/手机号/邮箱）、注册、登出、用户信息
- 📊 **数据库操作** — 链式调用的 CRUD（list / page / get / insert / insertBatch / update / delete）
- 🔍 **丰富过滤条件** — eq / neq / gt / gte / lt / lte / in / between / like / or
- 🚀 **项目管理 / 应用管理** — 与 JS SDK 完全一致的 API
- 🔌 **自定义 API** — `/api/{name}` 灵活调用
- 📁 **文件上传** — multipart 上传并返回后端 JSON
- 🔑 **自动 Token 管理** — 基于 Preferences 本地持久化，`setToken()` 保持同步语义
- 📦 **HAR 包发布** — 可发布到 ohpm 公共仓库，`ohpm install dayubase-ohos` 即用

## 环境要求

- HarmonyOS NEXT 5.0+ / OpenHarmony 5.0+（API 12 及以上）
- DevEco Studio 5.0+（构建工具链）

## 安装

在 `oh-package.json5` 中声明依赖（发布到公共仓库后）：

```json5
{
  "dependencies": {
    "dayubase-ohos": "^1.0.0"
  }
}
```

然后执行：

```bash
ohpm install
```

### 权限声明

宿主应用需要在 `module.json5` 中声明网络权限：

```json5
{
  "module": {
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" }
    ]
  }
}
```

## 快速开始

```typescript
import { createClient } from 'dayubase-ohos';

const client = createClient({
  baseUrl: 'https://your-api-endpoint.com',  // DayuBase 后端地址
  appId: 'your-app-id',                       // 可选：应用 ID
  apiKey: 'your-api-key',                     // 可选：API Key
  context: getContext(this)                   // 必须：宿主 UIAbility 上下文
});
```

## API 文档

### 认证模块 (auth)

```typescript
// 登录（用户名 / 手机号 / 邮箱三选一）
const result = await client.auth.login({
  phone: '13800138000',   // 或 user_name / email
  password: 'your-password'
});

// 注册
const result = await client.auth.register({
  user_name: 'newuser',
  password: 'your-password'
});

// 用户信息 / 登出
const user = await client.auth.getUser();
await client.auth.logout();

// 小程序 code 登录（业务方自行获取 code）
await client.auth.loginByWeapp('wx-code', 'wechat_users');
```

### 数据库模块 (db)

> 与 JS SDK 的差异：鸿蒙端链式查询以 **`.execute()`** 作为终止方法（ArkTS 不支持自定义 thenable 的 await）。

```typescript
// 列表查询 + 过滤 + 排序
const result = await client.db
  .from('users')
  .list()
  .eq('status', 'active')
  .gt('age', 18)
  .order('created_at', 'desc')
  .execute();

// 分页查询
const result = await client.db
  .from('users')
  .page()
  .page(1, 20)
  .eq('status', 'active')
  .execute();

// 单条查询
const result = await client.db.from('users').get().eq('id', 123).execute();

// 过滤操作符
// .eq / .neq / .gt / .gte / .lt / .lte / .in('field', ['a','b']) / .between('field', [1, 50]) / .like('name', '手机')
// OR 条件：
await client.db.from('users').list()
  .eq('status', 'active')
  .or((q) => { q.eq('role', 'admin').eq('role', 'moderator'); })
  .execute();

// 插入
const result = await client.db.from('users')
  .insert()
  .values({ name: 'John', email: 'john@example.com' })
  .execute();

// 批量插入
const rows: Object[] = [
  { name: 'A' },
  { name: 'B' }
];
const result = await client.db.from('users').insertBatch().values(rows).execute();

// 更新（条件 + 数据）
const result = await client.db.from('users')
  .update()
  .set({ status: 'inactive' })
  .eq('id', 123)
  .execute();

// 删除
const result = await client.db.from('users').delete().eq('id', 123).execute();
```

### 自定义 API 模块 (api)

```typescript
const result = await client.api
  .call('sendEmail')
  .param('to', 'user@example.com')
  .param('subject', 'Hello')
  .execute();

// 批量参数 / 自定义请求头
const result = await client.api
  .call('sendEmail')
  .params({ to: 'user@example.com', subject: 'Hello' })
  .header('X-Custom', 'value')
  .execute();
```

### 项目管理模块 (project)

```typescript
await client.project.page({ current: 1, pageSize: 10, projectName: '关键词' });
await client.project.create({ projectName: '我的项目', description: '描述' });
await client.project.overview('project-id');
await client.project.update('project-id', { projectName: '新名字' });
await client.project.delete('project-id');
```

### 应用管理模块 (app)

```typescript
await client.app.page({ projectId: 'project-id', current: 1, pageSize: 10 });
await client.app.create({ projectId: 'project-id', name: '我的应用' });
await client.app.overview('app-id');
await client.app.update('app-id', { appName: '新名字' });
await client.app.delete('app-id');
await client.app.recycle('app-id', { appId: 'app-id' });
await client.app.copy('app-id');
await client.app.export('app-id');
await client.app.import({ projectId: 'target-project-id' });
await client.app.getLoginInfo('app-id', 'relevance-id');
```

### 文件模块 (file)

```typescript
// uri 为文件路径或 file:// URI（可通过系统文件选择器获取）
const result = await client.file.upload('/data/storage/el2/base/haps/entry/files/a.jpg');

// 自定义文件名 / MIME / 请求头
const result = await client.file.upload(uri, {
  filename: 'photo.jpg',
  fileType: 'image/jpeg',
  headers: { 'X-Source': 'picker' }
});
// 返回 { code, success, data: { url, fileName, newFileName, originalFilename }, message }
```

### Token 管理

```typescript
client.setToken('your-auth-token');  // 登录成功自动保存；传 null 清除
```

## 与 JS SDK 的差异

| 差异点 | dayubase-js | dayubase-ohos |
| --- | --- | --- |
| 语言/平台 | JavaScript (Web/小程序) | ArkTS (HarmonyOS NEXT) |
| 链式查询终止 | `await` 直接作用于 builder | 显式调用 `.execute()` |
| 文件上传入参 | File 对象 / 小程序路径 | 文件路径或 `file://` URI |
| 本地存储 | localStorage / wx.storage | Preferences（`baas_token` 键） |
| 依赖注入 | 无需 | 必须传入 `context`（`getContext(this)`） |

## 本地开发与测试

```bash
# 构建 HAR（需要 DevEco Studio / OpenHarmony SDK 工具链）
hvigorw assembleHar
# 产物：library/build/default/outputs/default/dayubase-ohos.har

# 纯逻辑单元测试（Node + vitest，mock 掉 @kit.* 模块）
cd tests && npm install && npm test
```

## 发布到 ohpm 公共仓库

### 一次性前置（需人工完成）

1. 在 [ohpm 三方库中心仓](https://ohpm.openharmony.cn) 注册账号并**完成实名认证**（首次发布必需）；
2. 按 ohpm 文档配置发布凭证：`~/.ohpm/.ohpmrc` 中的 `publish_registry` / `publish_id` / `key_path` / `key_passphrase` / `crypto_path`；
3. 执行 `ohpm login` 登录。

### 一键发布

```bash
./publish.sh
```

脚本依次执行：registry 检查 → `hvigorw assembleHar` → `ohpm prepublish` 预检 → `ohpm publish`。

### 审核与版本

- 公共中心仓对首次发布及版本更新有自动 + 人工审核，请确保 README 与 LICENSE 完整；
- 同一版本不可覆盖，修订需递增版本号（修改 `library/oh-package.json5` 的 `version`）；
- 发布前可用 `cd library && ohpm prepublish` 单独预检。

## 已知限制

- 不支持旧 FA 模型（API < 12）；
- `@ohos.net.http` 的 `RequestMethod` 枚举未声明 **PATCH** 方法，SDK 通过类型断言以字符串 `"PATCH"` 传递（底层为标准 HTTP 方法字符串）。若目标后端在个别设备上不接受，可改用后端 PUT/POST 端点；
- token 持久化使用 `preferences.putSync` + 异步 `flush()`（`flushSync` 为 API 14+，为兼容 API 12 未使用），极端情况下（写入后进程立即被杀）存在丢失风险；
- `loginByWeapp` 面向小程序 code 登录场景，鸿蒙端需业务方自行获取 code；
- 文件上传入参为文件路径/URI，若文件来自系统选择器（如相册），请先通过 `fileUri` 等转换为可读路径；
- 本库为源码 HAR（`ohpm prepublish` 会提示源码包警告），如需混淆可开启 `library/build-profile.json5` 中的 release 混淆配置；
- 本机无鸿蒙真机/模拟器时，建议在 DevEco Studio 模拟器中做端到端联调。

## License

见仓库根目录 [LICENSE](../../LICENSE)。
