import "@testing-library/jest-dom/vitest";
import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { App } from "./App";
import { fetchHealth } from "./api/client";

vi.mock("./api/client", () => ({
  fetchHealth: vi.fn(),
}));

const mockedFetchHealth = vi.mocked(fetchHealth);

/**
 * 对应 spec「前端连通状态展示」的两个 Scenario：
 * 后端可达 -> 展示连通；请求失败/超时 -> 展示异常（而不是空白或崩溃）。
 */
describe("App 的后端连通状态展示", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("后端返回 ok 时展示连通提示", async () => {
    mockedFetchHealth.mockResolvedValue({ status: "ok" });

    render(<App />);

    expect(await screen.findByText("后端连通")).toBeInTheDocument();
  });

  it("请求失败时展示异常提示", async () => {
    mockedFetchHealth.mockRejectedValue(new Error("network down"));

    render(<App />);

    expect(await screen.findByText("后端连接异常")).toBeInTheDocument();
  });
});
