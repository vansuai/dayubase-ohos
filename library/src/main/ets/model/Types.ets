import { common } from '@kit.AbilityKit';

/**
 * 通用响应结构，与后端 BaseResponse 对应。
 * code == 0 时 success 为 true。
 */
export interface DayuBaseResponse<T> {
  code: number;
  data: T;
  message: string;
  success: boolean;
}

/**
 * 初始化客户端所需的配置。
 */
export interface CreateClientConfig {
  /** 后端服务地址，例如 https://api.example.com */
  baseUrl: string;
  /** 可选：应用 API Key（对应请求头 CODE_FLYING） */
  apiKey?: string;
  /** 可选：应用 ID（对应请求头 APP_ID） */
  appId?: string;
  /** 宿主应用上下文，通过 getContext(this) 获取；用于本地存储与文件上传 */
  context: common.Context;
}

/**
 * 请求选项，与 JS SDK 的 request(options) 保持一致。
 */
export interface RequestOptions {
  /** HTTP 方法：GET / POST / PUT / PATCH / DELETE ... */
  method?: string;
  /** 查询字符串参数，undefined/null 会被过滤 */
  params?: Record<string, Object>;
  /** 额外请求头 */
  headers?: Record<string, string>;
  /** 请求体（JSON 字符串） */
  body?: string;
}

/**
 * 文件上传选项。
 */
export interface UploadOptions {
  /** 文件 URI 或沙箱路径，例如 file://media/... 或 /data/storage/el2/base/.../a.jpg */
  uri: string;
  /** 额外请求头 */
  headers?: Record<string, string>;
  /** 上传的文件名（默认取 uri 最后一段） */
  filename?: string;
  /** 文件 MIME 类型（默认 application/octet-stream） */
  fileType?: string;
}

/**
 * 平台 HTTP 响应包装，与 JS SDK 平台层同形。
 */
export interface HttpResponseLike {
  json(): Promise<Object>;
  status: number;
}

/**
 * 本地存储抽象。
 */
export interface StorageLike {
  get(key: string): string | null;
  set(key: string, value: string): void;
  remove(key: string): void;
}

/**
 * HTTP 抽象。
 */
export interface HttpLike {
  request(url: string, options: RequestOptions): Promise<HttpResponseLike>;
  uploadFile(url: string, options: UploadOptions): Promise<HttpResponseLike>;
}

/**
 * 平台抽象（存储 + HTTP）。
 */
export interface PlatformLike {
  storage: StorageLike;
  http: HttpLike;
}

/**
 * 客户端最小接口，供各业务模块依赖（避免循环引用）。
 */
export interface ClientLike {
  baseUrl: string;
  apiKey: string | null;
  appId: string | null;
  token: string | null;
  platform: PlatformLike;
  setToken(token: string | null): void;
  request(path: string, options?: RequestOptions): Promise<Object>;
}

/**
 * 登录参数：user_name / phone / email 至少提供其一，password 必填。
 */
export interface LoginParams {
  user_name?: string;
  phone?: string;
  email?: string;
  password: string;
}

/**
 * 认证模块。
 */
export interface AuthModule {
  login(params: LoginParams): Promise<Object>;
  register(data: Record<string, Object>): Promise<Object>;
  getUser(): Promise<Object>;
  logout(): Promise<Object>;
  loginByWeapp(code: string, relevanceTable?: string): Promise<Object>;
}

/**
 * 自定义 API 模块。
 */
export interface ApiModule {
  call(apiName: string): ApiBuilderLike;
}

/**
 * 自定义 API 链式构建器。
 */
export interface ApiBuilderLike {
  param(key: string, value: Object): ApiBuilderLike;
  params(obj: Record<string, Object>): ApiBuilderLike;
  header(key: string, value: string): ApiBuilderLike;
  headers(obj: Record<string, string>): ApiBuilderLike;
  execute(): Promise<Object>;
}

/**
 * 数据库模块。
 */
export interface DbModule {
  from(table: string): QueryBuilderLike;
}

/**
 * 数据表查询入口。
 */
export interface QueryBuilderLike {
  list(): FilterBuilderLike;
  page(): FilterBuilderLike;
  get(): FilterBuilderLike;
  insert(): DataBuilderLike;
  insertBatch(): BatchDataBuilderLike;
  update(): DataBuilderLike;
  delete(): FilterBuilderLike;
}

/**
 * 过滤条件链式构建器（list / page / get / delete）。
 */
export interface FilterBuilderLike {
  eq(field: string, value: Object): FilterBuilderLike;
  neq(field: string, value: Object): FilterBuilderLike;
  gt(field: string, value: Object): FilterBuilderLike;
  gte(field: string, value: Object): FilterBuilderLike;
  lt(field: string, value: Object): FilterBuilderLike;
  lte(field: string, value: Object): FilterBuilderLike;
  in(field: string, values: Object[]): FilterBuilderLike;
  between(field: string, values: Object[]): FilterBuilderLike;
  like(field: string, value: Object): FilterBuilderLike;
  or(callback: (q: FilterBuilderLike) => void): FilterBuilderLike;
  page(number: number, size: number): FilterBuilderLike;
  order(field: string, direction?: string): FilterBuilderLike;
  execute(): Promise<Object>;
}

/**
 * 数据写入链式构建器（insert / update）。
 */
export interface DataBuilderLike extends FilterBuilderLike {
  values(data: Record<string, Object>): DataBuilderLike;
  set(data: Record<string, Object>): DataBuilderLike;
}

/**
 * 批量插入构建器。
 */
export interface BatchDataBuilderLike {
  values(dataArray: Object[]): BatchDataBuilderLike;
  execute(): Promise<Object>;
}

/**
 * 项目管理模块。
 */
export interface ProjectModule {
  page(params?: ProjectPageParams): Promise<Object>;
  create(data: Record<string, Object>): Promise<Object>;
  overview(projectId: string): Promise<Object>;
  update(projectId: string, data: Record<string, Object>): Promise<Object>;
  delete(projectId: string): Promise<Object>;
}

/**
 * 项目分页查询参数。
 */
export interface ProjectPageParams {
  current?: number;
  pageSize?: number;
  projectName?: string;
}

/**
 * 应用管理模块。
 */
export interface AppModule {
  page(params?: AppPageParams): Promise<Object>;
  create(data: Record<string, Object>): Promise<Object>;
  overview(appId: string): Promise<Object>;
  update(appId: string, data: Record<string, Object>): Promise<Object>;
  delete(appId: string): Promise<Object>;
  recycle(appId: string, data: Record<string, Object>): Promise<Object>;
  copy(appId: string): Promise<Object>;
  export(appId: string): Promise<Object>;
  import(data: Record<string, Object>): Promise<Object>;
  getLoginInfo(appId: string, relevanceId: string): Promise<Object>;
}

/**
 * 应用分页查询参数。
 */
export interface AppPageParams {
  projectId?: string;
  current?: number;
  pageSize?: number;
  name?: string;
}

/**
 * 文件模块。
 */
export interface FileModule {
  upload(uri: string, options?: UploadOptions): Promise<Object>;
}

/**
 * createClient 返回的门面对象。
 */
export interface BaaSFacade {
  setToken(token: string | null): void;
  auth: AuthModule;
  db: DbModule;
  api: ApiModule;
  project: ProjectModule;
  app: AppModule;
  file: FileModule;
}
