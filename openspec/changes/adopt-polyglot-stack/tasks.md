# Tasks

> 排序遵循测试先行：每组先有会失败的测试，再写让它通过的实现。脚手架/依赖类组不强摊测试。
> 实现细节的"怎么做"见 `design.md`；"建什么"见 `specs/health-check/spec.md`。

## 1. 后端工程骨架（脚手架）

- [x] 1.1 在 `apps/api` 生成最小 Spring Boot 工程并纳入 Maven wrapper（`mvnw`/`.mvn`），验证：`cd apps/api && ./mvnw -q -DskipTests compile` 成功、`./mvnw spring-boot:run` 能起（Ctrl-C 退出即可）
- [x] 1.2 加入 `springdoc-openapi` 依赖，验证：`cd apps/api && ./mvnw -q dependency:resolve` 成功解析（本组为脚手架，不含行为测试）

## 2. health-check 后端能力（测试先行）

- [x] 2.1 先写失败测试：MockMvc 断言 `GET /api/health` 返回 200 且响应体 `status` 字段为 `ok`，验证：实现前 `cd apps/api && ./mvnw -q test` 该测试为 RED
- [x] 2.2 实现 health 控制器与响应模型让 2.1 转 GREEN，验证：`./mvnw -q test` 通过
- [x] 2.3 断言该端点匿名可访问（无鉴权），验证：新增一个不带任何凭据的访问测试为 GREEN（对应 spec「无需鉴权即可访问」）
- [ ] 2.4 生成 `contracts/openapi.json` 并提交，验证：启动应用后 springdoc 输出含 `/api/health` 路径，且该文件落在 `contracts/` 并被 git 跟踪

## 3. 数据访问基座（PostgreSQL + JPA + Testcontainers）

- [ ] 3.1 先写失败测试：Testcontainers 起一次性 PostgreSQL 容器、加载含 DataSource 的 Spring 上下文并执行 `SELECT 1`，验证：无配置时 `./mvnw -q test` 该测试为 RED
- [ ] 3.2 配置 PostgreSQL 方言 + Spring Data JPA + Testcontainers 让 3.1 转 GREEN，验证：`./mvnw -q test` 通过（本切片不引入任何业务实体/领域模型）

## 4. 前端工程骨架（脚手架）

- [x] 4.1 在 `apps/web` 生成 React + Vite + TypeScript 工程并纳入 npm workspaces，验证：仓库根 `npm install` 后 `npm run build --workspace apps/web` 成功
- [x] 4.2 配置 dev server 将 `/api/*` 代理到后端，验证：`npm run dev --workspace apps/web` 启动后，经 dev server 访问 `/api/health` 能转发命中后端（curl 观测）

## 5. 契约 codegen

- [x] 5.1 接入 `openapi-typescript`，从 `contracts/openapi.json` 生成前端类型/客户端，验证：生成命令成功产出类型文件、可重复生成且结果稳定
- [x] 5.2 前端严格模式消费生成类型不报错，验证：`npm run typecheck --workspace apps/web` 通过

## 6. health 连通状态展示（测试先行）

- [x] 6.1 先写失败测试：React Testing Library mock 生成客户端，断言返回 ok 时渲染"连通"提示、请求失败/超时时渲染"异常"提示，验证：实现前 `npm run test --workspace apps/web` 为 RED
- [x] 6.2 实现首页组件调用生成客户端并渲染两种状态让 6.1 转 GREEN，验证：`npm run test --workspace apps/web` 通过（对应 spec 前端两个 Scenario）

## 7. 验证回路接入多语言

- [x] 7.1 给 `scripts/verify.sh` 增加 Maven 分支：检测到 `apps/api/pom.xml` 则跑 `./mvnw -q test`；JDK/Maven 缺失时该阶段记为"跳过=无法验证"而非静默通过，验证：本机有 JDK 时该阶段执行；把 `mvn` 移出 PATH 后脚本整体退出码不为 0（体现"无法验证"）
- [x] 7.2 给 `verify.sh` 增加契约一致性步骤（后端产 `openapi.json` → 前端 codegen → `tsc`），验证：人为使 `contracts/openapi.json` 与前端生成类型不一致时，该步骤变红
- [ ] 7.3 后端配置 CORS 允许 dev 前端来源，验证：跨源预检请求返回正确 `Access-Control-Allow-Origin`（测试或 curl 观测）

## 8. 骨架文档与决策记录

- [x] 8.1 更新 `openspec/config.yaml` 的 context 技术边界（polyglot：Node 前端 + JDK/Maven 后端；三栈落定；`packages/shared` 前端专用），验证：`npx openspec instructions proposal --change adopt-polyglot-stack --json` 返回的 context 反映新边界
- [x] 8.2 改写 `harness/context/architecture.md` 依赖图与目录职责表（新增 `contracts/`、`apps/api ──► contracts` 真相、`apps/web ──► packages/shared`），验证：文件内不再出现旧的 `apps/api ──► packages/shared` 边
- [x] 8.3 在 `harness/context/glossary.md` 登记新术语（契约真相/`contracts`、code-first、Testcontainers、连通状态等），验证：对应条目存在
- [x] 8.4 补根 `.gitignore`（`target/`、`*.class`、Java/IDE 产物）并确保 `mvnw` 可执行，验证：`git status` 不误纳构建产物、`ls -l apps/api/mvnw` 有执行位
- [x] 8.5 用 WebSearch 核实当前 Spring Boot 与 JDK 21 稳定版本，写 ADR `docs/decisions/NNNN-adopt-polyglot-stack.md`（含适用/失效条件，尤其"部署环境绑定 MySQL 则 D4 反转"），验证：ADR 文件存在、版本号附来源链接

## 9. 集成验证

- [x] 9.1 端到端手动验证：同起后端与前端，浏览器首页显示"连通"，验证：贴出后端 `GET /api/health` 的 curl 真实输出与前端页面状态描述
- [x] 9.2 运行 `bash scripts/verify.sh` 并把真实输出写入本变更 `verification.md`，验证：退出码为 0；若 JDK/Maven/Docker 缺失致某阶段"无法验证"，须在 `verification.md` 如实标注，不得声称通过

## Workflow follow-up

- 满足评审与 `harness/workflow/definition-of-done.md` 后运行 `/opsx:archive` 归档，`health-check` delta 合并进 `openspec/specs/health-check/spec.md`
- 归档后改写新主 spec 的 Purpose（若为占位 TBD），并确认 `architecture.md` 已同步
