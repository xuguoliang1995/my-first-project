# 验证证据 — adopt-polyglot-stack

- 日期：2026-10-29
- 环境：macOS 26.6.2（x86_64）｜Node v22.22.3 / npm 10.9.8｜Temurin JDK 21.0.13｜Maven 3.9.16
- 工具链位置：JDK 与 Maven 装在 `~/tools`，经 `~/.zprofile` 导出 `JAVA_HOME` / `PATH`；Maven 走阿里云镜像
- **Docker：本机未安装**，因此组 3（Testcontainers）未实施，见第 6 节

## 1. 任务完成情况

| 组 | 内容 | 状态 |
| --- | --- | --- |
| 1 | 后端工程骨架（mvnw / springdoc） | ✅ 完成 |
| 2 | health-check 后端能力（测试先行） | ✅ 完成 |
| 3 | 数据访问基座（PostgreSQL + JPA + Testcontainers） | ⛔ 未实施（缺 Docker） |
| 4 | 前端工程骨架（React + Vite） | ✅ 完成 |
| 5 | 契约 codegen | ✅ 完成 |
| 6 | health 连通状态展示（测试先行） | ✅ 完成 |
| 7 | 验证回路接入多语言（Maven / 契约 / CORS） | ✅ 完成 |
| 8 | 骨架文档与决策记录 | ✅ 完成 |
| 9 | 集成验证 | ✅ 完成 |

## 2. `verify.sh` 真实输出

命令：`NO_COLOR=1 zsh -lc 'bash scripts/verify.sh'`（登录 shell 以加载工具链 PATH）
**退出码：0**

```text
=== verify: my-first-project ===
阶段: spec typecheck lint test build
包:   apps/web packages/shared 

-- spec ------------------------------------------------------
   $ openspec validate --strict --no-interactive --all
✓ change/adopt-polyglot-stack
Totals: 1 passed, 0 failed (1 items)
   ^ 规约结构合法

-- typecheck -------------------------------------------------
   [apps/web] $ tsc --noEmit -p tsconfig.json
   [packages/shared] $ tsc --noEmit -p tsconfig.json

-- lint -------------------------------------------------
   跳过（没有包定义 "lint" 脚本）

-- test -------------------------------------------------
   [apps/web] $ vitest run

 RUN  v5.0.5 /Users/xuguoliang/Desktop/my-first-project/apps/web

 ✓ src/App.test.tsx (2 tests) 76ms

 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  15:51:04
   Duration  2.21s (environment 79%, setup 11%, import 4%, tests 4%, transform 2%)


-- build -------------------------------------------------
   [apps/web] $ tsc --noEmit -p tsconfig.json && vite build
vite v8.3.5 building client environment for production...
transforming...
✓ 16 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.33 kB │ gzip:  0.23 kB
dist/assets/index-C9lvnEJM.js  220.26 kB │ gzip: 69.05 kB

✓ built in 191ms

-- maven -----------------------------------------------------
   [apps/api] $ ./mvnw -q test
:: Spring Boot ::               (v3.5.16)

2026-10-29T15:51:17.187+08:00  INFO 81816 --- [my-first-project-api] [           main] c.e.myfirstproject.HealthControllerTest  : Starting HealthControllerTest using Java 21.0.13 with PID 81816 (started by xuguoliang in /Users/xuguoliang/Desktop/my-first-project/apps/api)
2026-10-29T15:51:19.348+08:00  INFO 81816 --- [my-first-project-api] [           main] c.e.myfirstproject.HealthControllerTest  : Started HealthControllerTest in 2.659 seconds (process running for 4.717)
2026-10-29T15:51:20.764+08:00  INFO 81816 --- [my-first-project-api] [           main] .b.t.c.SpringBootTestContextBootstrapper : Found @SpringBootConfiguration com.example.myfirstproject.ApiApplication for test class com.example.myfirstproject.CorsConfigTest

-- contract --------------------------------------------------
   $ npm run codegen --workspace apps/web
   ^ 前端生成类型与 contracts/openapi.json 一致

=== 汇总 ===
通过: 6   跳过阶段: 1   无法验证: 0

结论: 验证通过（exit 0）。
```

> 说明：Maven 段的 Spring Boot 启动日志已按上文保留关键行（完整输出含 Mockito/ByteBuddy 的
> JDK 动态 agent 警告，属上游库行为，不影响测试结果）。
> `lint` 阶段被跳过是事实：仓库尚无 ESLint 配置，不是"跑通了"。

## 3. 测试先行证据（RED → GREEN）

| 任务 | RED 证据（失败原因 = 功能缺失） | GREEN 证据 |
| --- | --- | --- |
| 2.1 → 2.2 | `Status expected:<200> but was:<404>` | `Tests run: 2, Failures: 0` |
| 6.1 → 6.2 | `findByText("后端连通")` 找不到，2 tests failed | `Tests: 2 passed (2)` |
| 7.3 CORS | `Status expected:<200> but was:<403>`（预检被拒） | `Tests run: 3, Failures: 0` |

## 4. 端到端集成验证（任务 9.1）

后端 `apps/api`（8080）与前端 dev server（5190，5173 被本机其他项目占用）同时启动：

```
$ curl -s http://127.0.0.1:8080/api/health
{"status":"ok"}                      HTTP 200

$ curl -s http://127.0.0.1:5190/api/health   # 经 Vite dev server 代理
{"status":"ok"}                      HTTP 200
```

浏览器验证（真实渲染，非 curl 静态 HTML）：

- 页面可见文本：标题 `my-first-project`，正文 **`后端连通`**
- 控制台：无 error / warn
- 截图：`/tmp/verify-backend-status.png`
- 判定：✅ 成功（未停留在"正在检查"，未出现"后端连接异常"）

## 5. 验证回路的反向验证（防止假绿灯）

| 场景 | 命令 | 结果 |
| --- | --- | --- |
| 缺少 JDK | `env -u JAVA_HOME PATH="<node>:…:/usr/bin:/bin" bash scripts/verify.sh` | maven 段报"无法验证"，**exit 2** ✅ |
| 契约结构性漂移 | 给 `HealthResponse` 注入多余字段后跑 verify | contract 段报"生成类型与契约不一致"，**exit 1** ✅ |
| 契约仅元数据变化 | 只改 `info.title` | 判"一致"——**已知局限**，不影响类型则不报警，已记入 ADR 负面后果 |

## 6. 未完成项与遗留（如实标注）

1. **组 3（PostgreSQL + JPA + Testcontainers）未实施** —— 本机无 Docker daemon，
   Testcontainers 无法启动容器，任何"通过"都不可信，故**不实施也不声称完成**。
   补齐方式：安装 Docker Desktop 后按 `tasks.md` 3.1 / 3.2 继续（先写红灯测试）。
2. 仓库尚无 ESLint 配置，`verify.sh` 的 `lint` 阶段一直是"跳过"。新增 lint 属独立变更。
3. `packages/shared` 目前无实际内容（仅占位），已降级为前端专用，边界在 ADR 中固化。
4. 部署形态（容器化 / CI）仍为待定，不在本变更范围。
5. 生产 CORS 白名单未收敛：当前放行 `http://localhost:*` / `http://127.0.0.1:*`，仅适用 dev。
