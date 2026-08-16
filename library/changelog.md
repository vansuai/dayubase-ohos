# Changelog

## 1.0.0 - 2025-08-16

### 首次发布
- DayuBase BaaS HarmonyOS SDK（ArkTS，HarmonyOS NEXT API 12+）
- 认证模块：登录（用户名/手机号/邮箱）、注册、用户信息、登出、小程序 code 登录
- 数据库模块：链式 CRUD（list / page / get / insert / insertBatch / update / delete）与过滤条件（eq / neq / gt / gte / lt / lte / in / between / like / or）
- 自定义 API 模块：`/api/{name}` 链式调用
- 项目管理 / 应用管理模块：与 JS SDK 端点一致
- 文件上传模块：multipart 上传并返回后端 JSON
- 自动 Token 管理：Preferences 本地持久化，`setToken()` 同步语义
