# 验证证据 — adopt-polyglot-stack

- 日期：2026-10-29（组 3 于当日补齐，见第 7 节）
- 环境：macOS 26.6.2（x86_64）｜Node v22.22.3 / npm 10.9.8｜Temurin JDK 21.0.13｜Maven 3.9.16｜Docker Desktop 29.9.2
- 工具链位置：JDK 与 Maven 装在 `~/tools`，经 `~/.zprofile` 导出 `JAVA_HOME` / `PATH`；Maven 走阿里云镜像
- Docker：`/Applications/Docker.app`，daemon 经 `~/.docker/run/docker.sock`；已配国内镜像加速器（Docker Hub 直连超时，见第 7 节）

## 1. 任务完成情况

| 组 | 内容 | 状态 |
| --- | --- | --- |
| 1 | 后端工程骨架（mvnw / springdoc） | ✅ 完成 |
| 2 | health-check 后端能力（测试先行） | ✅ 完成 |
| 3 | 数据访问基座（PostgreSQL + JPA + Testcontainers） | ✅ 完成（当日补齐） |
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
16:10:22.101 [main] INFO org.testcontainers.DockerClientFactory -- Testcontainers version: 1.21.4
16:10:22.951 [main] INFO ...DockerClientProviderStrategy -- Found Docker environment with Docker accessed via Unix socket (/Users/xuguoliang/.docker/run/docker.sock)
16:10:22.984 [main] INFO org.testcontainers.DockerClientFactory -- Connected to docker:
  Server Version: 29.9.2
  Operating System: Docker Desktop
16:10:24.006 [main] INFO ...RyukResourceReaper -- Ryuk started - will monitor and terminate Testcontainers containers on JVM exit
16:10:24.007 [main] INFO tc.postgres:16-alpine -- Creating container for image: postgres:16-alpine
16:10:32.389 [main] INFO com.zaxxer.hikari.pool.HikariPool -- HikariPool-2 - Added connection org.postgresql.jdbc.PgConnection@582b6362
        Database version: 16.15
16:10:32.663 [main] INFO c.e.myfirstproject.PersistenceTest -- Started PersistenceTest in 0.701 seconds (process running for 12.128)

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
| 3.1 → 3.2 数据访问 | `NoSuchBeanDefinitionException: No qualifying bean of type 'javax.sql.DataSource'`（JPA/驱动/数据源全缺） | `Tests run: 4, Failures: 0, Errors: 0, Skipped: 0` / `BUILD SUCCESS` |

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

## 6. 遗留（如实标注）

1. **Docker Desktop 需手动启动**：daemon 由 GUI 进程托管，机器重启后要打开一次 Docker。
   未启动时 Testcontainers 相关测试会真实失败（`verify.sh` maven 阶段变红），这是正确判定，
   不会被当成"环境跳过"。
2. 仓库尚无 ESLint 配置，`verify.sh` 的 `lint` 阶段一直是"跳过"。新增 lint 属独立变更。
3. `packages/shared` 目前无实际内容（仅占位），已降级为前端专用，边界在 ADR 中固化。
4. 部署形态（容器化 / CI）仍为待定，不在本变更范围。
5. 生产 CORS 白名单未收敛：当前放行 `http://localhost:*` / `http://127.0.0.1:*`，仅适用 dev。

## 7. 组 3 补齐记录（2026-10-29）

### 7.1 环境准备：Docker 从零安装

| 步骤 | 实际结果 |
| --- | --- |
| 下载 Docker Desktop（amd64） | 629,594,318 字节，34s（17.2 MB/s） |
| 安装到 `/Applications` | `hdiutil attach` + `cp -R`，无需 sudo |
| 启动 daemon | `open -a Docker` → 20s 后 `docker info` 可用，Server 29.9.2 |
| 首次拉取 | **失败**：`registry-1.docker.io` 超时（`context deadline exceeded`，60.7s） |

Docker Hub 不可达 → 在 `~/.docker/daemon.json` 增加 `registry-mirrors`（原文件已备份到 `~/tools/daemon.json.bak.*`），
重启后生效：

```text
 Registry Mirrors:
  https://docker.m.daocloud.io/
  https://docker.1ms.run/
  https://docker.xuanyuan.me/
  https://hub.rat.dev/
```

拉取复测：`hello-world` 3.2s，`postgres:16-alpine` 33s（420MB）。

### 7.2 Testcontainers 路径（任务 3.1 / 3.2）

RED（实现前，失败原因 = 功能缺失，不是环境问题）：

```text
Caused by: NoSuchBeanDefinitionException: No qualifying bean of type 'javax.sql.DataSource' available
[ERROR]   PersistenceTest.canExecuteSelectOne » UnsatisfiedDependency
```

GREEN（加 `spring-boot-starter-data-jpa` + `postgresql` 驱动 + 数据源配置之后）：

```text
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0 -- in HealthControllerTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0 -- in PersistenceTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0 -- in CorsConfigTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Testcontainers 自动发现 Docker Desktop 的 socket，**不需要** `DOCKER_HOST` 或 `~/.testcontainers.properties`。

### 7.3 引入 JPA 的连带影响（必须同批修，否则既有能力回退）

| 影响 | 现象 | 处理 |
| --- | --- | --- |
| 所有 `@SpringBootTest` 都需要数据源 | HealthControllerTest / CorsConfigTest 由绿转红：`Connection to 127.0.0.1:5432 refused` | 抽 `AbstractIntegrationTest`：单例容器（static 块启动）+ `@DynamicPropertySource`，三个测试类共用同一个 PostgreSQL（PersistenceTest 耗时降到 0.7s） |
| 应用本身起不来 | `./mvnw spring-boot:run` 失败，`/api/health` 返回 000——**9.1 的端到端能力被回退** | 加 `apps/api/compose.yaml` + `spring-boot-docker-compose`（runtime / optional），启动时自动拉起 PostgreSQL 并接管连接信息 |

### 7.4 应用启动路径（compose）验证

```text
$ ./mvnw spring-boot:run
...DockerComposeLifecycleManager : Using Docker Compose file .../apps/api/compose.yaml
...ApiApplication : Started ApiApplication in 11.328 seconds

$ curl -s http://127.0.0.1:8080/api/health
{"status":"ok"}                      HTTP 200

$ docker ps
postgres:16-alpine  Up 14 seconds (healthy)  0.0.0.0:5432->5432/tcp

$ docker exec <container> psql -U myfirstproject -d myfirstproject -c "SELECT 1 AS ok;"
 ok
----
  1
(1 row)
```

`spring-boot-docker-compose` 默认 `spring.docker.compose.skip.in-tests=true`，因此测试阶段仍走 Testcontainers，
不会与 compose 路径互相干扰。

### 7.5 仍未验证的边界

- 容器化部署（应用镜像构建、CI 中的 Docker）不在本变更范围。
- `ddl-auto=validate` 在**存在实体**时才真正校验表结构；本切片无实体，该路径尚未被真实表结构检验过。
- Docker Desktop 首次安装未安装 privileged helper，`/var/run/docker.sock` 不存在；Testcontainers 与 compose
  均通过 `~/.docker/run/docker.sock` 工作，若后续引入只认 `/var/run/docker.sock` 的工具需另行处理。
