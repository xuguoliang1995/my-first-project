# apps/web

前端可部署单元：**React 19 + Vite 8 + TypeScript（strict）**，纯 SPA（CSR）。

选型依据见 `docs/decisions/0002-adopt-polyglot-stack.md`。

## 开发

```bash
npm install                          # 在仓库根执行，一次装好所有 workspace
npm run dev --workspace apps/web     # 默认 http://localhost:5173
```

dev server 把 `/api/*` 代理到 `http://127.0.0.1:8080`，因此需要后端同时运行。
代理目标刻意写 `127.0.0.1` 而非 `localhost`：本机 `localhost` 优先解析到 `::1`，
与后端 IPv4 监听错位会表现为连接超时。

## 脚本

| 命令 | 作用 |
| --- | --- |
| `npm run dev --workspace apps/web` | 启动 dev server |
| `npm run test --workspace apps/web` | Vitest + Testing Library |
| `npm run typecheck --workspace apps/web` | `tsc --noEmit` |
| `npm run build --workspace apps/web` | 类型检查 + 生产构建 |
| `npm run codegen --workspace apps/web` | 由 `contracts/openapi.json` 重新生成 `src/api/schema.d.ts` |

`src/api/schema.d.ts` 是**生成物**，不要手改——改了下一次 `codegen` 就丢，
且 `scripts/verify.sh` 的 contract 阶段会判红。

## 边界

- 不直接连数据库；数据一律经 `apps/api`
- 不手写后端 API 类型，类型全部由契约派生
- 只依赖 `packages/shared`（类型与纯函数）与本包内部模块
