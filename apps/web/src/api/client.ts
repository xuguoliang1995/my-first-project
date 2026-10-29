import type { operations } from "./schema";

/**
 * 健康探针成功响应的类型——直接取自 openapi.json 的生成结果，
 * 不手写镜像：后端改契约后重新 codegen，这里会跟着变、编译期即暴露不一致。
 */
export type HealthResponse =
  operations["health"]["responses"][200]["content"]["*/*"];

export const HEALTH_ENDPOINT = "/api/health";

/**
 * 调用后端健康探针。
 *
 * 网络错误、超时（由传入的 signal 控制）与非 2xx 一律抛出，
 * 由调用方决定如何呈现——本函数不吞异常。
 */
export async function fetchHealth(signal?: AbortSignal): Promise<HealthResponse> {
  const response = await fetch(HEALTH_ENDPOINT, signal ? { signal } : {});
  if (!response.ok) {
    throw new Error(`健康探针请求失败：HTTP ${response.status}`);
  }
  return (await response.json()) as HealthResponse;
}
