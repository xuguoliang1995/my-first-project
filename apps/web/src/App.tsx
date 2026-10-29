import { useEffect, useState } from "react";
import { fetchHealth } from "./api/client";

type ConnectionState = "checking" | "ok" | "error";

/** 超过该时长未响应即视为不可达，避免页面长时间停在"检查中" */
const HEALTH_TIMEOUT_MS = 5000;

export function App() {
  const [connection, setConnection] = useState<ConnectionState>("checking");

  useEffect(() => {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), HEALTH_TIMEOUT_MS);

    fetchHealth(controller.signal)
      .then(() => setConnection("ok"))
      .catch(() => setConnection("error"))
      .finally(() => clearTimeout(timeoutId));

    return () => {
      clearTimeout(timeoutId);
      controller.abort();
    };
  }, []);

  return (
    <main>
      <h1>my-first-project</h1>
      {connection === "checking" && <p>正在检查后端连通状态…</p>}
      {connection === "ok" && <p>后端连通</p>}
      {connection === "error" && <p>后端连接异常</p>}
    </main>
  );
}
