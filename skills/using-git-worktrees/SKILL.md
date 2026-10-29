---
name: using-git-worktrees
description: 用 git worktree 为任务提供隔离工作区，避免未完成代码污染主干、避免并行任务互相覆盖。当任务改动较大、需要并行多条线、或主干必须始终保持可运行时使用。
---

# 技能：using-git-worktrees（隔离工作区）

## 何时使用

- 一个变更需要多天，但主干必须始终可运行
- 同时推进两条互不相关的改动
- 需要在不打断当前工作的情况下验证别人的分支
- 高风险重构，想保留一个干净对照

**不必使用**：单文件小改动（worktree 的开销大于收益）。

## 基本操作

```bash
# 为变更创建隔离工作区（分支名遵循 harness/rules/30）
git worktree add ../my-first-project-<change-id> -b feat/<change-id>

# 查看现有工作区
git worktree list

# 完成后移除（分支仍保留）
git worktree remove ../my-first-project-<change-id>
```

## 与本项目流程的衔接

| 步骤 | 位置 |
| --- | --- |
| 创建变更 | 主工作区（`openspec/changes/<id>/` 需要提交） |
| 实现 | worktree 内 |
| 验证 | worktree 内跑 `bash scripts/verify.sh` |
| 归档 | 合并回主工作区后 `npx openspec archive <id> -y` |

注意：`node_modules` 不在 git 内，新 worktree 需要重新 `npm install`。

## 纪律

- 一个 worktree 只对应一个变更，不要在里面顺手做第二件事
- **不要在 worktree 里 `git checkout` 主干**，那会让隔离失效
- 删除 worktree 前确认：改动已合并或已明确丢弃
- 多个 worktree 并行时，文件集合不得相交（与 `subagent-driven-development` 同一约束）

## 退出标准

- [ ] worktree 路径与分支名可对应到变更 id
- [ ] 隔离区内跑通过一次 `verify.sh`
- [ ] 合并/丢弃决策已记录
- [ ] 残留 worktree 已清理（`git worktree list` 无孤儿）

## 反模式

- 为了"隔离"给每个小任务都开 worktree
- 在 worktree 之间手工复制文件（应该走 git）
- 忘记清理，半年后发现 12 个孤儿 worktree
