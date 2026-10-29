# 术语表

> 同一概念在代码、规约、对话里必须用同一个词。发现新术语就加进来，
> 出现同义词立即统一，否则智能体会在不同文件里造出三套命名。

## 架构术语

| 术语 | 定义 | 不要混淆 |
| --- | --- | --- |
| 变更（change） | 一次有边界的功能改动，对应 `openspec/changes/<id>/` 一个目录 | 不是 git commit，一个变更可含多个提交 |
| delta spec | 相对当前行为的增量规约，只写 ADDED / MODIFIED / REMOVED / RENAMED | 不是完整 spec |
| 真相来源 | `openspec/specs/`，描述系统**当前**行为 | 不是设计文档 |
| 垂直切片 | 从 UI 到存储打通的最小完整功能 | 不是"先写完所有接口" |
| 闸门（gate） | 必须满足才能继续的检查点 | 不是建议 |
| 能力（capability） | `openspec/specs/` 下的一级目录，等同「规约域」 | 不是代码模块 |

## 工作流术语

| 术语 | 定义 |
| --- | --- |
| 澄清（clarify） | 动手前把模糊点问清楚，一次只问一个问题 |
| 计划（plan） | 拆成可独立验证的原子任务，落到 `openspec/changes/<id>/tasks.md` |
| 红灯（red） | 测试失败且失败原因是功能缺失 |
| 绿灯（green） | 测试通过，且没有为通过而削弱断言 |
| 验证证据（evidence） | 命令的真实输出，落档到 `changes/<id>/verification.md` |
| 归档（archive） | `openspec archive` 把 delta 合并进主 spec，变更移入 `archive/` |
| 三态验证 | `verify.sh` 的 0 通过 / 1 失败 / 2 无法验证 |
| 技能（skill） | `skills/<name>/SKILL.md`，一类任务的可复用套路 |
| 子智能体（subagent） | 由 `.qoder/agents/*.md` 定义、用于隔离上下文或并行的执行单元 |

## 契约与跨栈术语

| 术语 | 定义 | 不要混淆 |
| --- | --- | --- |
| 契约真相（contract） | `contracts/openapi.json`，描述前后端可交互的接口表面，由后端生成 | 不是手写文档，也不是前端类型 |
| code-first | 契约由后端代码注解生成，而非先写 YAML 再生成代码 | 不是 design-first |
| 派生类型（generated types） | `apps/web/src/api/schema.d.ts`，由契约经 openapi-typescript 生成 | 不允许手改，改了下一次 codegen 就丢 |
| 契约漂移（contract drift） | 契约变了但派生类型没重新生成 | 不是版本号不一致；`verify.sh` 会判红 |
| 连通状态 | 前端对健康探针结果的展示态：连通 / 异常 | 不是后端存活探针本身 |

## 后端与数据术语

| 术语 | 定义 |
| --- | --- |
| 健康探针（health check） | 系统对外暴露的、匿名可访问的存活查询接口 |
| Testcontainers | 测试期用 Docker 起一次性数据库容器，跑完即弃 |
| 单例容器（singleton container） | 用 static 块启动、整个测试 JVM 共用一个容器；与 `@Container` 的"按测试类起容器"相对 |
| 本地开发编排（compose） | `apps/api/compose.yaml` 定义的本地 PostgreSQL；由 `spring-boot-docker-compose` 在应用启动时自动拉起 |
| 镜像加速器（registry mirror） | `~/.docker/daemon.json` 里的 `registry-mirrors`；本机无法直连 Docker Hub，缺它则拉不到任何镜像 |
| 无法验证（unverified） | 因缺少工具链/产物而未执行的检查；`verify.sh` 以 exit 2 表达，绝不能当作通过 |
| Maven wrapper（mvnw） | 随仓库携带的 Maven 启动器，不需要全局安装 `mvn`，但必须有 JDK |

## 业务术语

> 技术栈与业务确定后在此追加：

| 术语 | 定义 |
| --- | --- |
| （待补充） | 业务定名后填写，注明英文对照与代码中的实际命名 |

## 命名对照约定

- 中文术语 ↔ 代码标识符必须一一对应，新增业务概念时**先在此登记再写代码**
- 同一概念不同叫法（如「用户 / 会员 / 账号」）必须选一个作为规范词，其余只在说明中提及
