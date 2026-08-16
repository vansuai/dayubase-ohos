import { common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { DayuBaseError } from '../client/DayuBaseError';
import { HttpLike, HttpResponseLike, PlatformLike, RequestOptions, StorageLike, UploadOptions } from '../model/Types';

/** 本地偏好存储文件名 */
const PREF_NAME: string = 'dayubase';

/** 平台 HTTP 响应实现 */
class HttpResponseImpl implements HttpResponseLike {
  status: number;
  private text: string;

  constructor(text: string, status: number) {
    this.text = text;
    this.status = status;
  }

  json(): Promise<Object> {
    return Promise.resolve(JSON.parse(this.text));
  }
}

/** 基于 @ohos.data.preferences 同步接口的本地存储（setToken 可保持同步语义） */
class OhosStorage implements StorageLike {
  private context: common.Context;
  private prefs: preferences.Preferences | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  private getPrefs(): preferences.Preferences {
    if (this.prefs === null) {
      const options: preferences.Options = {} as preferences.Options;
      options.name = PREF_NAME;
      this.prefs = preferences.getPreferencesSync(this.context, options);
    }
    return this.prefs;
  }

  get(key: string): string | null {
    const value: preferences.ValueType = this.getPrefs().getSync(key, '');
    return typeof value === 'string' && value !== '' ? value : null;
  }

  set(key: string, value: string): void {
    this.getPrefs().putSync(key, value);
    this.flushAsync();
  }

  remove(key: string): void {
    this.getPrefs().deleteSync(key);
    this.flushAsync();
  }

  /**
   * 异步落盘（fire-and-forget，保持 setToken 同步语义）。
   * flushSync 是 API 14+ 才有的接口，为兼容 API 12 使用异步 flush()。
   */
  private flushAsync(): void {
    const p: Promise<void> = this.getPrefs().flush();
    p.catch((err: Error) => {
      // 持久化失败不阻塞业务（token 仍在内存中，本次会话可用）
      console.warn(`dayubase: preferences flush failed: ${err.message}`);
    });
  }
}

/** 基于 @ohos.net.http 的 HTTP 实现；文件上传使用手动 multipart 构造以获取响应体 JSON */
class OhosHttp implements HttpLike {
  request(url: string, options: RequestOptions): Promise<HttpResponseLike> {
    const httpRequest: http.HttpRequest = http.createHttp();
    const emptyHeaders: Record<string, string> = {};
    const reqOptions: http.HttpRequestOptions = {};
    reqOptions.method = OhosHttp.toRequestMethod(options.method);
    reqOptions.header = options.headers === undefined ? emptyHeaders : options.headers;
    reqOptions.expectDataType = http.HttpDataType.STRING;
    reqOptions.connectTimeout = 30000;
    reqOptions.readTimeout = 30000;
    if (options.body !== undefined) {
      reqOptions.extraData = options.body;
    }
    return httpRequest.request(url, reqOptions).then((response: http.HttpResponse): HttpResponseLike => {
      httpRequest.destroy();
      return new HttpResponseImpl(OhosHttp.toResultText(response.result), response.responseCode as number);
    }).catch((err: Error) => {
      httpRequest.destroy();
      throw new DayuBaseError(`网络请求失败: ${err.message}`, -1);
    });
  }

  uploadFile(url: string, options: UploadOptions): Promise<HttpResponseLike> {
    let fileData: ArrayBuffer;
    try {
      const stat: fileIo.Stat = fileIo.statSync(options.uri);
      const size: number = stat.size;
      fileData = new ArrayBuffer(size);
      const file: fileIo.File = fileIo.openSync(options.uri, fileIo.OpenMode.READ_ONLY);
      fileIo.readSync(file.fd, fileData);
      fileIo.closeSync(file);
    } catch (e) {
      return Promise.reject(new DayuBaseError(`文件不存在或无法访问: ${options.uri} (${String(e)})`, -1));
    }

    const boundary: string = `dayubaseBoundary${Date.now().toString()}`;
    const filename: string = options.filename === undefined ? OhosHttp.basename(options.uri) : options.filename;
    const fileType: string = options.fileType === undefined ? 'application/octet-stream' : options.fileType;
    const headerPart: string = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\nContent-Type: ${fileType}\r\n\r\n`;
    const tailPart: string = `\r\n--${boundary}--\r\n`;

    const encoder: util.TextEncoder = new util.TextEncoder();
    const headerDest: Uint8Array = new Uint8Array((headerPart.length + 1) * 4);
    const headerInfo: util.EncodeIntoUint8ArrayInfo = encoder.encodeIntoUint8Array(headerPart, headerDest);
    const headerBytes: Uint8Array = headerDest.subarray(0, headerInfo.written);
    const tailDest: Uint8Array = new Uint8Array((tailPart.length + 1) * 4);
    const tailInfo: util.EncodeIntoUint8ArrayInfo = encoder.encodeIntoUint8Array(tailPart, tailDest);
    const tailBytes: Uint8Array = tailDest.subarray(0, tailInfo.written);

    const body: ArrayBuffer = new ArrayBuffer(headerBytes.byteLength + fileData.byteLength + tailBytes.byteLength);
    const bodyView: Uint8Array = new Uint8Array(body);
    bodyView.set(headerBytes, 0);
    bodyView.set(new Uint8Array(fileData), headerBytes.byteLength);
    bodyView.set(tailBytes, headerBytes.byteLength + fileData.byteLength);

    const headers: Record<string, string> = {};
    headers['Content-Type'] = `multipart/form-data; boundary=${boundary}`;
    if (options.headers !== undefined) {
      const keys: string[] = Object.keys(options.headers);
      for (let i = 0; i < keys.length; i++) {
        headers[keys[i]] = options.headers[keys[i]];
      }
    }

    const httpRequest: http.HttpRequest = http.createHttp();
    const reqOptions: http.HttpRequestOptions = {};
    reqOptions.method = http.RequestMethod.POST;
    reqOptions.header = headers;
    reqOptions.extraData = body;
    reqOptions.expectDataType = http.HttpDataType.STRING;
    reqOptions.connectTimeout = 60000;
    reqOptions.readTimeout = 60000;
    return httpRequest.request(url, reqOptions).then((response: http.HttpResponse): HttpResponseLike => {
      httpRequest.destroy();
      return new HttpResponseImpl(OhosHttp.toResultText(response.result), response.responseCode as number);
    }).catch((err: Error) => {
      httpRequest.destroy();
      throw new DayuBaseError(`文件上传失败: ${err.message}`, -1);
    });
  }

  private static toResultText(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result;
    }
    return JSON.stringify(result);
  }

  private static basename(uri: string): string {
    let path: string = uri;
    const qIndex: number = path.indexOf('?');
    if (qIndex >= 0) {
      path = path.substring(0, qIndex);
    }
    const slashIndex: number = path.lastIndexOf('/');
    return slashIndex >= 0 ? path.substring(slashIndex + 1) : path;
  }

  private static toRequestMethod(method: string | undefined): http.RequestMethod {
    const m: string = (method === undefined || method === '') ? 'GET' : method.toUpperCase();
    switch (m) {
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      case 'OPTIONS':
        return http.RequestMethod.OPTIONS;
      case 'HEAD':
        return http.RequestMethod.HEAD;
      case 'PATCH':
        // @ohos.net.http 的 RequestMethod 枚举未声明 PATCH，但枚举值为字符串，
        // 底层实现接受标准 HTTP 方法字符串，这里通过类型断言传递 "PATCH"。
        return 'PATCH' as http.RequestMethod;
      default:
        return http.RequestMethod.GET;
    }
  }
}

/**
 * 鸿蒙平台适配层。
 */
export class OhosPlatform implements PlatformLike {
  readonly storage: StorageLike;
  readonly http: HttpLike;

  constructor(context: common.Context) {
    this.storage = new OhosStorage(context);
    this.http = new OhosHttp();
  }
}
