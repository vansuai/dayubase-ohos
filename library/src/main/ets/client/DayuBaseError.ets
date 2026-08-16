/**
 * SDK 自定义错误。
 */
export class DayuBaseError extends Error {
  /** HTTP 状态码或自定义错误码，无则 -1 */
  status: number;

  constructor(message: string, status: number = -1) {
    super(message);
    this.status = status;
  }
}
