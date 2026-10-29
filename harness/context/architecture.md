# 架构全景

> 本文件是智能体的**系统认知入口**。每完成一个变更，若架构有变，必须同步更新。
> 原则：**只写当前真实存在的结构**，不写设想的未来结构。

## 当前状态

| 项 | 值 |
| --- | --- |
| 阶段 | polyglot 骨架已落地，首个垂直切片 `health-check` 打通（后端探针 + 前端连通展示） |
| 前端技术栈 | React + Vite，纯 SPA（CSR），`apps/web` |
| 后端技术栈 | Spring Boot 3.5.x + Spring Data JPA，Maven wrapper，JDK 21，`apps/api` |
| 数据库 | PostgreSQL（开发与测试；测试用 Testcontainers 起一次性容器） |
| 跨栈契约 | `contracts/openapi.json`，后端 springdoc 代码优先生成，前端派生类型 |
| 部署形态 | 待定（不在当前变更范围） |
| 包管理 | npm workspaces（`apps/*`、`packages/*`，单 `package-lock.json`）+ Maven（`apps/api`） |
| 验证回路 | `scripts/verify.sh`，三态退出码 0/1/2；含 Maven 与契约一致性阶段 |
| 规约工具链 | `@fission-ai/openspec` CLI（`openspec/config.yaml` 声明 `schema: spec-driven`） |

选型依据见 `docs/decisions/0002-adopt-polyglot-stack.md`（含适用条件与失效条件）。

## 目录职责

| 路径 | 职责 | 边界 |
| --- | --- | --- |
| `apps/web` | 前端可部署单元（React + Vite） | 不直接连数据库；不手写后端 API 类型 |
| `apps/api` | 后端可部署单元（Spring Boot） | 不包含 UI 逻辑；不依赖 `packages/shared` |
| `contracts/` | **跨栈契约真相**（`openapi.json`） | 只由后端生成，前端只读消费 |
| `packages/shared` | 前端共享的**类型与纯函数** | 零 I/O、零框架依赖；只服务前端 |
| `harness/` | 智能体执行约束 | 不含业务代码 |
| `openspec/` | 行为规约 | 不含实现细节 |
| `skills/` | 工作流技能定义（真身，逐项链接进 `.qoder/skills/`） | 不含业务代码 |
| `.qoder/` | IDE 集成：钩子配置、斜杠命令、子智能体、openspec 生成文件 | 只引用技能，不重复规则 |

## 依赖方向（不可逆）

```
apps/web ──┬──► packages/shared            （TS 类型与纯函数）
           └──► contracts/openapi.json      （派生 API 类型，只读）

apps/api ─────► contracts/openapi.json      （springdoc 产出契约，写入端）

packages/shared  ──►  （无下游，标准库除外）
contracts/       ──►  （无下游，纯数据）
```

`apps/api` 与 `packages/shared` 之间**没有依赖边**——后端不是 TS 工程，
跨栈一致性只经 `contracts/` 保证。反向依赖一律禁止：
`packages/shared` 指向 `apps/*`、前端手改 `contracts/` 或手写后端类型，都视为架构破坏。

## 工具链分层

```
openspec CLI   → 变更的创建 / 校验 / 归档（权威结构判据）
verify.sh      → 类型 / 静态 / 测试 / 构建（权威执行判据）
git pre-commit → 把 verify.sh 变成不可绕过的闸门
.qoder/settings.json
  SessionStart → 会话开始注入必读清单与仓库快照
  PreToolUse   → 拦截 git commit --no-verify 与 git push --force
```

## 引入新技术的收敛方式

技术栈已落定；后续任何新依赖/新栈仍走同一路径：

1. 新建变更：`bash scripts/new-change.sh <topic>`
2. 在 `design.md` 列 2-3 个候选与权衡（重点写**放弃了什么**）
3. 在 `docs/decisions/` 写 ADR，含适用条件与失效条件
4. 更新本文件的「当前状态」表格
5. 跑通 `verify.sh`（新增阶段必须重新定义"无法验证"的判定，不能默认跳过）

## 已知约束

- 前端：Node ≥ 22，npm workspaces 管理多包
- 后端：JDK 21 + Maven wrapper（`apps/api/mvnw`）；不需要全局 `mvn`，但必须有 JDK
- 数据库测试：Testcontainers 需要可用的 Docker；Docker 缺失时 `apps/api` 的库相关测试无法验证
- 跨栈一致性：改后端接口 → 重新生成 `contracts/openapi.json` → 前端 `codegen`，三步缺一即 `verify.sh` 红
- 业务代码从可在一次会话内完成的最小切片起步（垂直切片优先于水平铺开）
- `verify.sh` 不依赖具体包管理器（直接读各包 `package.json` 的 scripts）
- `verify.sh` 退出码 2 表示"无法验证"——它不等于通过，任务仍是未完成状态

## 踩坑记录（本地环境）

- macOS 的 `/usr/bin/java` 是存根：`command -v java` 会成功但执行报 "Unable to locate a Java Runtime"。
  探测 JDK 必须**真实执行** `java -version`，不能只判断命令存在。
- 本机 `localhost` 优先解析到 `::1`；Vite 代理与后端 IPv4 监听错位会表现为"连接超时"（不是连接拒绝）。
  dev 代理目标写 `127.0.0.1` 而非 `localhost`。
