# my-first-project

全栈 Web 应用骨架，按 **Harness + OpenSpec + Superpowers** 三层理念组织，供 AI 编码智能体与人协作开发。

## 三层职责

| 层 | 目录 | 作用 |
| --- | --- | --- |
| 意图层 | `openspec/` | 用 requirement + scenario 定义系统行为；变更以 delta 提案，归档后合并为真相来源（官方 CLI 兼容） |
| 执行层 | `harness/` | 规则、上下文、质量闸门、循环协议、三态验证回路 |
| 方法层 | `skills/` | 可复用的工作流技能：澄清、计划、执行、子智能体、TDD、排障、评审、验证、分支收尾 |

## 快速开始

```bash
npm install                # 安装 typescript 与 openspec CLI
bash scripts/install-hooks.sh   # 接线 git pre-commit 闸门
bash scripts/new-change.sh add-hello-endpoint "新增 Hello 接口"
bash scripts/verify.sh     # 三态验证：0 通过 / 1 失败 / 2 无法验证
```

包管理器为 **npm workspaces**（单一 `package-lock.json`，避免双 lockfile 漂移）。

## 验证语义

`scripts/verify.sh` 有意区分三种结果，避免「什么都没跑」被当成通过：

| 退出码 | 含义 |
| --- | --- |
| 0 | 至少一个检查真实执行且全部通过 |
| 1 | 有检查失败 |
| 2 | **无法验证**（所有阶段被跳过 / 未安装依赖）——禁止表述为完成 |

## 当前状态

- 技术栈：**待定**（见 `harness/context/architecture.md`，选型要走 `choose-*-stack` 变更）
- `apps/web`、`apps/api` 为占位，选型后填充
- `packages/shared` 已提供最小类型契约与 `typecheck` 回路

详细约定见 [AGENTS.md](./AGENTS.md)。
