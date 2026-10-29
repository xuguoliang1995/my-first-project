import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      // 契约里后端路径已带 /api 前缀，代理不再重写路径。
      // 刻意写 127.0.0.1 而非 localhost：本机 localhost 优先解析到 ::1，
      // 与后端 IPv4 监听错位会导致代理连接超时。
      "/api": {
        target: "http://127.0.0.1:8080",
        changeOrigin: true,
      },
    },
  },
});
