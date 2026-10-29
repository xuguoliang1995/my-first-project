---
name: finishing-a-development-branch
description: 开发分支的收尾流程：确认验证通过、归档变更、合并到主干、清理工作区。当一条分支上的工作即将完成时使用。不适用于变更尚未验证或 delta spec 尚未归档的情况。
---

# 技能：finishing-a-development-branch（分支收尾）

## 收尾前的硬条件

缺任何一条都不算可合并：

- [ ] `bash scripts/verify.sh` 退出码 **0**（2 = 无法验证，不可合并）
- [ ] `openspec validate --strict` 通过
- [ ] `changes/<id>/verification.md` 已写入
- [ ] `tasks.md` 全部勾选，或有记录的未完成项
- [ ] 无 TODO 遗留（或已关联变更 id 与移除条件）

## 步骤

### 1. 自检

```bash
bash scripts/verify.sh; echo "exit=$?"
npx openspec validate --strict
git status
git diff main...HEAD --stat
```

### 2. 归档变更（在合并前）

```bash
npx openspec archive <change-id> -y
```

归档会把 delta 合并进 `openspec/specs/`，并把变更目录移入 `archive/`。
这一步**必须先做**，否则主干上的 specs 与实现会脱节。

### 3. 更新架构认知

- 架构有变 → 更新 `harness/context/architecture.md`
- 新术语 → 更新 `harness/context/glossary.md`
- 重要取舍 → 新增 `docs/decisions/NNNN-*.md`

### 4. 提交与合并

```bash
git add -A
git commit -m "feat(<scope>): <为什么这么做>

Refs: openspec/changes/<id>"
git checkout main
git merge --no-ff feat/<change-id>
```

提交信息遵循 `harness/rules/30-security-and-git.md`。

### 5. 清理

```bash
git branch -d feat/<change-id>
git worktree remove ../my-first-project-<change-id>   # 若用过 worktree
```

### 6. 汇报

按 `AGENTS.md` 第 10 节的四项格式：变更 / 改动 / 验证 / 遗留。

## 合并被阻断时

| 现象 | 处理 |
| --- | --- |
| verify 退出码 1 | 回到 `systematic-debugging`，不要 `--no-verify` |
| verify 退出码 2 | 补上检查或依赖，不得"先合了再说" |
| 与主干冲突 | 先 rebase 到最新主干，再重跑全量验证 |
| 归档后 specs 与实现不一致 | 说明 delta 写漏了，补一个修正变更，不要偷偷改 specs |

## 退出标准

- [ ] 主干上 `verify.sh` 退出码 0
- [ ] 变更已归档，`openspec/specs/` 反映新行为
- [ ] 架构/术语/ADR 已同步
- [ ] 分支与 worktree 已清理
- [ ] 四项汇报齐全

## 反模式

- 先合并再补归档
- 用 `--no-verify` 绕过钩子
- 把"CI 会跑"当成"我验证过了"
- 归档时手工搬目录（specs 不会更新）
