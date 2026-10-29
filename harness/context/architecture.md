# 架构全景

> 本文件是智能体的**系统认知入口**。每完成一个变更，若架构有变，必须同步更新。
> 原则：**只写当前真实存在的结构**，不写设想的未来结构。

## 当前状态

| 项 | 值 |
| --- | --- |
| 阶段 | 骨架初始化，尚无业务代码 |
| 前端技术栈 | **待定** |
| 后端技术栈 | **待定** |
| 数据库 | 待定 |
| 部署形态 | 待定 |
| 包管理 | npm workspaces（`apps/*`、`packages/*`，单 `package-lock.json`） |
| 验证回路 | `scripts/verify.sh`，三态退出码 0/1/2 |
| 规约工具链 | `@fission-ai/openspec` CLI（`openspec/config.yaml` 声明 `schema: spec-driven`） |

技术栈未定是**刻意**的：选型本身要走一次 openspec 变更，产出 ADR 记录在 `docs/decisions/`。

## 目录职责

| 路径 | 职责 | 边界 |
| --- | --- | --- |
| `apps/web` | 前端可部署单元 | 不直接连数据库 |
| `apps/api` | 后端可部署单元 | 不包含 UI 逻辑 |
| `packages/shared` | 跨端共享的**类型与纯函数** | 零 I/O、零框架依赖 |
| `harness/` | 智能体执行约束 | 不含业务代码 |
| `openspec/` | 行为规约 | 不含实现细节 |
| `skills/` | 工作流技能定义（真身，逐项链接进 `.qoder/skills/`） | 不含业务代码 |
| `.qoder/` | IDE 集成：钩子配置、斜杠命令、子智能体、openspec 生成文件 | 只引用技能，不重复规则 |

## 依赖方向（不可逆）

```
apps/web ──┐
           ├──► packages/shared
apps/api ──┘

packages/shared  ──►  （无下游，标准库除外）
```

反向依赖一律禁止。`packages/shared` 指向 `apps/*` 视为架构破坏，评审必须拒绝。

## 工具链分层

```
openspec CLI   → 变更的创建 / 校验 / 归档（权威结构判据）
verify.sh      → 类型 / 静态 / 测试 / 构建（权威执行判据）
git pre-commit → 把 verify.sh 变成不可绕过的闸门
.qoder/settings.json
  SessionStart → 会话开始注入必读清单与仓库快照
  PreToolUse   → 拦截 git commit --no-verify 与 git push --force
```

## 待定项的收敛方式

1. 新建变更：`bash scripts/new-change.sh choose-<topic>-stack`
2. 在 `design.md` 列 2-3 个候选与权衡（重点写**放弃了什么**）
3. 在 `docs/decisions/` 写 ADR，含适用条件与失效条件
4. 更新本文件的「当前状态」表格
5. 实现首个垂直切片，跑通 `verify.sh`

## 已知约束

- Node ≥ 22，npm workspaces 管理多包
- 业务代码从可在一次会话内完成的最小切片起步（垂直切片优先于水平铺开）
- `verify.sh` 不依赖具体包管理器（直接读各包 `package.json` 的 scripts）
