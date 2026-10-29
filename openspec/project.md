# 项目约定（OpenSpec）

> 本文件描述**跨变更稳定的约定**：技术边界、质量基线、评审规则。
> 单次改动的意图写在 `changes/<id>/proposal.md`，不要写在这里。

## 项目定位

my-first-project：全栈 Web 应用。当前处于骨架阶段，业务功能尚未开始。
因此技术选型一栏为「待定」，选型必须通过变更流程落地并回填此处。

## 技术边界

| 项 | 约束 |
| --- | --- |
| 运行环境 | Node ≥ 22 |
| 包管理 | npm workspaces（`apps/*`、`packages/*`，单 `package-lock.json`） |
| 语言 | TypeScript 优先，`strict` 开启（`tsconfig.base.json`） |
| 前端框架 | 待定 |
| 后端框架 | 待定 |
| 数据库 | 待定 |
| 契约共享 | 跨端类型与纯函数放 `packages/shared` |
| 规约工具链 | `@fission-ai/openspec` CLI，schema 固定为 `spec-driven` |

## 规约书写规则

1. **spec 只写外部可观察行为**，不写类名、函数名、库名、目录结构
2. 需求用 RFC 2119 关键词：`MUST` / `SHALL` 绝对要求，`SHOULD` 推荐，`MAY` 可选
3. 每条需求至少一个可测试的 `Scenario`，用 GIVEN / WHEN / THEN
4. **默认 Lite 规格**：短、行为优先、几条验收点即可；
   仅当涉及跨团队、API 契约变更、数据迁移、安全隐私时才写全量规格
5. delta spec 只写变化部分（ADDED / MODIFIED / REMOVED / RENAMED），不复述全文
6. 规范词与代码标识符的对照，先登记到 `harness/context/glossary.md`

## 变更规模判据

| 情形 | 处理 |
| --- | --- |
| 拼写、注释、格式 | 直接改，不开变更 |
| 单一能力内的行为调整 | Lite：proposal + delta spec + tasks + verification |
| 引入新依赖、改技术栈、改数据模型 | 全量：+ design.md + ADR |
| 跨包契约变更（`packages/shared` 类型变化） | 全量：+ 同步两端 + 兼容性说明 |
| 认证、鉴权、权限模型 | 全量：+ design.md + ADR（强制） |

## 质量基线（与 harness 对齐）

- 测试先行，禁止先写实现再补测试
- `bash scripts/verify.sh` 退出码必须为 0（2 = 无法验证，视为未完成）
- 验证输出写入 `changes/<id>/verification.md`
- 归档使用 `npx openspec archive <id> -y`，不手工搬目录
- 完成的定义见 `harness/gates/definition-of-done.md`

## 非目标

- 本仓库不承载部署脚本、CI 配置、容器化（后续独立变更引入）
- 不追求一次性设计完整架构；按垂直切片逐步演进
- 不维护自造的 changes 模板：模板与结构以官方 CLI 输出为准
