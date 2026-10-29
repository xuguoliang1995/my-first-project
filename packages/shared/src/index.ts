/**
 * @my-first-project/shared
 *
 * 跨端共享的**类型与纯函数**。硬约束（见 harness/rules/10-code.md）：
 * - 零 I/O：不出现 fetch / fs / window / process
 * - 零框架依赖：不依赖 React、后端框架或数据库客户端
 * - 只允许被 apps/* 依赖，禁止反向依赖
 *
 * 技术栈确定后，把领域类型放在这里；两端共用同一份定义，避免契约漂移。
 */

/** 服务端与前端统一使用的接口响应外层结构。 */
export type ApiResult<TData> =
  | { readonly ok: true; readonly data: TData }
  | { readonly ok: false; readonly error: ApiError }

/** 可供前端展示的错误结构。内部细节（堆栈、SQL、路径）不得出现在 message 中。 */
export type ApiError = {
  /** 机器可读的错误码，用于前端分支判断与日志聚合。 */
  readonly code: string
  /** 面向用户的文案，不包含内部实现信息。 */
  readonly message: string
}

/** 骨架阶段的占位导出，用于验证包可被正确解析；有真实领域类型后删除。 */
export const SHARED_PACKAGE_NAME = '@my-first-project/shared' as const
