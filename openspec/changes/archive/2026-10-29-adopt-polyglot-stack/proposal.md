# Proposal

## Why

仓库流程骨架已定型，但技术栈一直刻意留空（`config.yaml` context 写明「前端框架、后端框架、数据库：待定」）。要开始承载真实业务，必须先落定一套可验证的全栈选型，并让它与既有的 harness（`verify.sh`、openspec、packages/shared）咬合，否则每个后续功能都会在「用什么栈、契约怎么对齐」上重复从零摸索。

## What Changes

- 后端落定为 **Spring Boot 3.x + Maven + Spring Data JPA**，运行于 **JDK 21 (LTS)**，落地在 `apps/api`。
- 前端落定为 **React + Vite 纯 SPA（CSR）**，落地在 `apps/web`。
- 数据库落定为 **PostgreSQL**（开发/CI 用 Testcontainers 起一次性实例）。
- 建立**跨栈契约的单一真相**：后端用 springdoc 产出 `openapi.json` 并提交到 `contracts/`，前端用 openapi-typescript 生成 TS 客户端/类型。契约一致性纳入 `verify.sh`。
- `packages/shared` 角色收缩为**仅前端**的纯工具与类型；后端不再 import 它（原 `apps/api → packages/shared` 依赖在 Java 下不成立）。
- 交付**首个垂直切片**：新增 `GET /api/health` 返回 `{status:"ok"}`，前端首页调用并显示连通状态，端到端跑通 OpenAPI→codegen→typecheck 这条缝。
- 连带更新骨架：`config.yaml` 技术边界、`architecture.md` 依赖图与目录职责、`verify.sh` 增加 maven 分支与契约一致性检查、根 `.gitignore` 补 Java 产物、新增 `mvnw`/`contracts/`、dev 环境前端 proxy 与后端 CORS。

## Capabilities

### New Capabilities
- `health-check`: 系统对外暴露一个可观测的健康探针，供前端与运维判断后端是否存活并返回结构化状态。

### Modified Capabilities
（无。本变更不修改任何既有 spec 的需求级行为——当前 `openspec/specs/` 为空。）

## Impact

- **新增代码单元**：`apps/api`（Spring Boot Maven 工程）、`apps/web`（React+Vite）、`contracts/openapi.json`。
- **契约**：`packages/shared` 从「跨端」降级为「前端专用」；跨栈真相迁移到 `contracts/openapi.json`。
- **执行层（harness）**：`scripts/verify.sh` 需支持多语言（新增 `mvn` 阶段 + 契约生成/校验）；`harness/context/architecture.md` 依赖图与目录职责表需改写；`openspec/config.yaml` context 技术边界需更新。
- **工具链/依赖**：引入 JDK、Maven wrapper、springdoc、openapi-typescript、Vite、React、Testcontainers。新增 ADR：`docs/decisions/NNNN-adopt-polyglot-stack.md`。
- **变更规模**：属**全量变更**（依据 `config.yaml`「引入新依赖、改技术栈、改数据模型、跨包契约」判据），需完整 `design.md` + ADR。

## 非目标（Out of scope）

- 不做部署脚本、CI 流水线、容器化与生产环境编排（`config.yaml` 既有非目标）。
- 不在本变更引入任何业务领域模型与鉴权/权限体系——首个切片只做 `health-check`，真正业务功能另开变更。
- 不做前端 SSR / SEO（纯 SPA，需要时后续变更再评估）。
- 不重写现有 harness 规则与方法层技能，仅按选型需要更新受影响的骨架文件。
