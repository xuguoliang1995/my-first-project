# 0002 采用 Spring Boot + React 多语言单仓

- 状态：已采纳
- 日期：2026-10-29
- 关联变更：`openspec/changes/adopt-polyglot-stack`

## 背景

骨架仓库原先把 Node/TypeScript 刻进了默认路径：`scripts/verify.sh` 只认各包
`package.json` 的 `typecheck/lint/test/build`，`packages/shared` 是 TS 工程，
`harness/context/architecture.md` 的依赖图画着 `apps/api ──► packages/shared`。
而实际需求是一个 **Spring Boot（Maven）后端 + React 前端** 的项目。

若不在动手前定下这件事，会出现三个具体问题：

1. `apps/api` 若是 Java，那条 TS 依赖边物理上不成立，架构文档会立刻说谎；
2. 没有跨语言契约机制时，前端只能手抄后端 DTO，接口一改就静默错位；
3. `verify.sh` 不认识 Maven，后端测试实际上永远不会被跑到，等于没有闸门。

## 决策

**B2：多语言单仓** —— `apps/web`（React + Vite，npm）+ `apps/api`（Spring Boot + Maven）
同仓共存，跨栈一致性经 **`contracts/openapi.json`（OpenAPI code-first）** 保证。

具体落定：

| 维度 | 选择 |
| --- | --- |
| 仓库形态 | 单仓双工具链：npm workspaces 管前端与 `packages/*`，Maven 管 `apps/api` |
| 跨栈契约 | OpenAPI **code-first**：springdoc 从 controller 注解产 `contracts/openapi.json`，前端 `openapi-typescript` 派生类型 |
| 前端 | React + Vite，纯 SPA（CSR），dev server 代理 `/api` |
| 后端 | Spring Boot **3.5.16** + Spring Data JPA + Maven wrapper |
| JDK | **21（LTS）** |
| 数据库 | PostgreSQL；测试用 Testcontainers |
| `packages/shared` | 降级为**前端专用**，后端不依赖它 |

版本依据（2026-10-29 核实）：

- Spring Boot 3.5.16 发布公告：<https://spring.io/blog/2026/06/25/spring-boot-3-5-16-available-now>
- 当前 Spring Boot GA 主版本已是 4.1.2：<https://spring.io/projects/spring-boot>
- Temurin JDK 21.0.13（2026-10-22）：<https://adoptium.net/temurin/releases/?version=21>
- Maven 3.9.16：`maven-metadata.xml` 实查（阿里云镜像），本机安装版本一致

## 理由

- **后端留在 Maven/JVM 生态**：需求明确要求 Spring Boot + Maven，这是硬约束，不是偏好。
- **前端留在 Vite**：SPA 已满足"展示连通状态"这类交互；引入 SSR 会带来 node 服务与部署复杂度，
  与本变更"最小垂直切片"的目标不符。
- **契约 code-first 而非 design-first**：团队只有一个后端实现者时，先写 YAML 再生成代码会产生
  "YAML 与实现不一致"的第二份真相；从实现生成契约则只有一份真相。
- **3.5.x 而非 4.1.x**：Spring Boot 4.x 虽已 GA，但 springdoc 与部分生态适配仍在跟进；
  3.5.x 仍在维护线（2026-06 仍有发布），迁移成本更低。**这是有意的时间点选择，不是遗漏。**
- **Testcontainers 而非 H2**：H2 与 PostgreSQL 在 SQL 方言、类型、约束上有差异，
  用 H2 绿灯不代表生产可用；Testcontainers 用真实 PostgreSQL，代价是需要 Docker。

## 放弃的方案

| 方案 | 放弃原因 |
| --- | --- |
| B1 全 Maven（前端也由 Java 服务托管，如 Thymeleaf） | 放弃 SPA 的交互与前端工具链；React 生态与热更新体验全部丢掉 |
| A / B3 前后端拆成两个仓库 | 小团队下双仓会导致契约版本对齐靠人工；本变更恰恰要靠单仓 + 原子提交保证契约同步 |
| design-first（先写 `openapi.yaml` 再生成后端） | 两份真相：YAML 与 controller 会漂移，且需要额外代码生成插件 |
| 手写前后端镜像类型 | 编译期无法发现漂移，属于本变更要消除的失败模式 |
| Next.js（SSR） | 需要 node 运行时与额外部署单元，超出首个切片所需 |
| Vue | 与 React 能力对等；此处按用户显式选择 React，非技术否决 |
| H2 内存库做测试 | 与 PostgreSQL 方言差异导致假绿灯 |
| MySQL | 当前无既有数据库绑定；若部署环境强制 MySQL，本决策的 D4 部分反转（见下方适用条件） |
| MyBatis / jOOQ | 首个切片只需 `SELECT 1` 级别的验证，JPA 的运维与上手成本更低；后续复杂查询场景可复议 |

## 后果

**正面：**

- 后端测试真正进入 `verify.sh` 闸门，不再是"写了但没人跑"
- 契约变更会自动让前端类型跟着变；不一致时构建直接红，漂移无法悄悄进主干
- `packages/shared` 边界变清晰：只服务前端，不再假装"跨端"
- 首个垂直切片（`health-check`）能端到端验证整条链路：controller → 契约 → 派生类型 → 组件

**负面（必须写）：**

- **双工具链**：贡献者需要同时具备 Node 22+ 与 JDK 21；`verify.sh` 变复杂
- **Docker 成为测试前置**：Testcontainers 需要可用的 Docker daemon，缺失时相关阶段"无法验证"
- **构建时间上升**：Maven 首次依赖解析明显慢于 npm
- **Boot 3.5.x 是追赶线**：4.x 迁移债务已存在，需要后续变更处理
- **契约阶段只能发现"影响生成类型的漂移"**：仅改 `info.title` 这类元数据不会触发红灯

## 适用条件

- 团队接受单仓双工具链，且 CI/开发机可提供 JDK 21 与 Docker
- 前端保持 SPA 形态（无 SSR/SEO 硬需求）
- 数据库为 PostgreSQL，或至少未绑定其他引擎
- Spring Boot 停在 3.5.x 维护线期间有效
- **若部署环境强制 MySQL**：保留多语言单仓与 OpenAPI 契约，但 D4（PostgreSQL + Testcontainers）
  需翻转——改用 MySQL 镜像做 Testcontainers，并重写本 ADR 对应条目

## 失效条件

- 需要 SSR / SEO / 首屏直出 → 重新评估 Next.js 或 node 服务托管
- Spring Boot 4.x 生态（尤其 springdoc）适配成熟 → 开迁移变更，升级并重写本 ADR
- 前端需要与后端共享运行时逻辑（而非仅类型）→ 契约方案不足，需重新设计共享层
- 团队规模增长到需要前后端独立发版节奏 → 重新评估拆仓方案（B3）
- Docker 在目标环境中不可用 → Testcontainers 策略失效，需改为外部测试数据库
