# Design

## Context

动机见 `proposal.md - Why`。此处只交代影响方案选型的现状与约束：

- 仓库流程骨架（harness + openspec + superpowers）已定型，但**执行回路是为单一语言写的**：`scripts/verify.sh` 通过遍历各包 `package.json` 的 `typecheck/lint/test/build` 脚本来验证，根 `package.json` 用 npm workspaces 聚合 `apps/*`、`packages/*`。
- `harness/context/architecture.md` 现有依赖图写死 `apps/api ──► packages/shared`，而 `packages/shared` 是 TypeScript——后端一旦是 JVM 语言，这条边物理上不成立。
- `openspec/config.yaml` context 第 14-17 行把「Node/npm workspaces/TS」当作项目技术边界，且三个框架/数据库标注「待定」。本变更即是兑现这些「待定」。

## Goals / Non-Goals

**Goals:**
- 让**两套构建系统（Maven + npm）在同一仓库共存且都能被 `verify.sh` 覆盖**，而不是各跑各的、验证只覆盖一半。
- 用一条**机器强制的契约缝**（OpenAPI → codegen → typecheck）取代"靠人自觉同步"，把前后端漂移变成红灯。
- 以最小垂直切片（`health-check`）端到端验证整套链路，再让业务功能增量叠加。

**Non-Goals:**
- 设计层面的边界，补充 `proposal.md` 非目标之外：不追求生产级可观测性（探针只做存活信号，不含依赖健康聚合/指标导出）；不在本次把 `verify.sh` 抽象成通用多语言框架，只为「Node + Maven」这一组合加最小分支。

## Decisions

### D1 仓库形态：多语言单仓（B2），而非全 Maven（B1）或拆两仓（A/B3）
- **选择**：`apps/api`（Spring Boot/Maven）与 `apps/web`（React/npm）同仓共存。
- **放弃 B1（前端也进 Maven，Thymeleaf 服务端渲染）**：会大面积作废现有 Node 骨架（`verify.sh`、npm workspaces、`packages/shared`），前期成本最高，且把 SPA 的交互能力也一起丢掉。
- **放弃 A/B3（另起独立仓库）**：与"就用这套已固化的 harness 流程"矛盾，会让本仓库的规约/闸门形同虚设。
- **代价**：仓库从此是混合构建，认知负担上升——用 D2/D6 把复杂度收敛到可验证的边界内。

### D2 契约缝：OpenAPI code-first（springdoc 产 spec → openapi-typescript 生成前端类型）
- **选择**：后端从 controller 注解产出 `openapi.json`，提交进 `contracts/`；前端从该文件生成 TS 客户端/类型。
- **放弃「手写 `packages/shared` 类型、后端手工镜像」**：正是最易漂移的做法，违背骨架"验证不允许自欺"的原则。
- **放弃「中立 schema（JSON Schema / protobuf）双端生成」**：对 REST+JSON 的单后端单前端属过度设计，生态摩擦大；未来若上 gRPC/多语言客户端再评估。
- **放弃「design-first（先手写 openapi.yaml 再生成后端桩）」**：会引入生成桩代码与手写业务代码的边界纠缠；code-first 让后端代码保持唯一权威、spec 派生，更贴合 JPA/注解风格。**前提**：契约一致性必须由验证强制（见 D6），否则 code-first 的 spec 仍可能滞后于代码。

### D3 前端：React + Vite 纯 SPA（CSR）
- **选择**：Vite 构建的 SPA，独立于后端运行时，dev 期通过 proxy 调后端。
- **放弃 Next.js（SSR）**：与「后端是 Spring Boot REST」叠加会多出一层 Node 运行时，加重混合构建；SEO 非当前目标。
- **放弃 Thymeleaf**：与 D1/B2 矛盾。
- **Vue 3 未选**：与 React 在本缝上无实质差异，纯团队熟悉度问题——本项目按 React 生态与 openapi-typescript 搭配推进。

### D4 数据访问：PostgreSQL + Spring Data JPA，开发/CI 用 Testcontainers
- **选择**：JPA 实体映射，方言锁定 PostgreSQL；测试用 Testcontainers 起一次性实例。
- **放弃 H2 当正式选型**：仅作内存测试库会因方言差异埋雷，不用于任何验证路径的"真相"。
- **放弃 MySQL**：无既定部署约束时，PostgreSQL 的 JSON/约束/JPA 支持更省心；**若公司环境绑定 MySQL，此决定应反转**（见 Open Questions）。
- **放弃 MyBatis/jOOQ**：首个切片无复杂 SQL 诉求，JPA 起步最薄；引入手写 SQL 层留待有明确需求时另开变更。

### D5 `packages/shared` 角色收缩为前端专用
- **选择**：它只保留「前端纯工具与类型」，零 I/O、零框架依赖的约束不变；跨栈真相迁移到 `contracts/openapi.json`。
- **放弃维持"跨端共享"名义**：Java 侧无法 import TS，保留旧定位会让 architecture.md 说谎。

### D6 `verify.sh` 增加 Maven 分支与契约一致性检查
- **选择**：`verify.sh` 在现有 npm 包枚举之外，检测 `apps/api/pom.xml` 存在则跑 `mvn -q test`；并加一步「后端产 `openapi.json` → 前端 codegen → `tsc`」的链路校验。保持三态退出码语义（0 通过 / 1 失败 / 2 无法验证）——若本机无 JDK/Maven，Maven 阶段记为**跳过**并可被识别为"未真正验证"，而非静默通过。
- **放弃**：不改用 Maven 独占的聚合构建（如把 npm 塞进 frontend-maven-plugin），那会让前端脱离 `npm workspaces` 骨架、改动过大。

## Risks / Trade-offs

- **[混合构建下"通过"语义被稀释：只跑了 npm 没跑 mvn 却报绿]** → D6 明确 JDK/Maven 缺失时 Maven 阶段为"跳过=无法验证"，并在汇总裁决里区分；`verification.md` 必须贴出 mvn 与 npm 两段真实输出。
- **[code-first 的 openapi.json 滞后于后端代码]** → 把「重新生成 spec」纳入 verify/CI 链路，产物提交进 `contracts/` 做 diff；spec 与前端生成类型不一致时 `tsc` 报错。
- **[JDK/Node 双运行时使本地环境与 CI 准备变重]** → 用 Maven wrapper（`mvnw`）固定构建工具版本，降低"我这能跑你那不能跑"。
- **[Testcontainers 需要可用 Docker]** → 无 Docker 环境时相关测试阶段应明确报"无法验证"而非跳过冒充通过。
- **[范围蔓延：顺手开始搭业务模型/鉴权]** → 非目标已锁定首个切片只做 `health-check`，其余另开变更。

## Migration Plan

1. 先落骨架（`mvnw` + 最小 Spring Boot 应用 + React+Vite 应用 + `contracts/`），不动既有 openspec/harness 逻辑。
2. 接 springdoc 与 openapi-typescript，跑通一条 `health-check` 端到端。
3. 更新 `config.yaml` / `architecture.md` / `verify.sh` / `.gitignore`，让新栈进入验证回路。
4. 写 ADR 固化选型；`verify.sh` 通过后归档，`health-check` delta 合并进主 spec。
- **回滚**：本变更在合并主 spec 前，回滚 = 删除该变更目录 + 还原被改的骨架文件；`apps/*` 新增内容彼此隔离，不影响流程骨架本身。

## Open Questions

（可安全延后、不影响 spec/方案/任务拆分的未知项）
- 精确的 Spring Boot 稳定小版本与 JDK 21 具体补丁版本——在写 ADR 时以 WebSearch 核实当前发布线后固定，不改变本设计结构。
- 前端 dev 是否需要固定端口/域名约定、后端 CORS 白名单具体值——属实现细节，apply 阶段定即可。
- 生产环境是否已绑定特定数据库（会触发 D4 反转）——本变更为非目标（不承载部署），留待部署相关变更确认。
