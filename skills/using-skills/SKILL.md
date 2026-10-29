---
name: using-skills
description: 元技能。任务开始前用来决定"该用哪个技能"，并说明多个技能如何串联。当不确定该走哪套流程、或发现自己准备凭直觉动手时使用。
---

# 技能：using-skills（技能发现）

## 为什么需要它

技能存在，不代表会被用上。没有这一步，智能体会**凭直觉写代码**，
然后把项目里所有规则退化成一堆没人执行的文档。

## 入口：先查索引，再动手

1. 读 `AGENTS.md` 第 5 节「技能索引」表
2. 识别当前任务属于哪类信号（模糊需求 / 要拆解 / 要写码 / 报错 / 要交付）
3. 打开对应 `skills/<name>/SKILL.md`，按它的**退出标准**执行
4. 一个任务可能命中多个技能——按下面的链路串联，不要只挑一个
5. `/opsx:*` 只管**规约产物**（建、改、归档）；手写技能管**怎么做对**。
   走 OPSX 时手写技能照样要用，尤其是 `/opsx:apply` 期间的测试先行与完成前验证

## 典型链路

| 场景 | 链路 |
| --- | --- |
| 新功能 | brainstorming → writing-plans → test-driven-development → requesting-code-review → verification-before-completion |
| 新功能（走 OPSX） | `/opsx:explore`（+ brainstorming）→ `/opsx:propose` → `/opsx:apply`（+ test-driven-development）→ verification-before-completion → `/opsx:archive` |
| 修 bug | systematic-debugging → test-driven-development（回归测试）→ verification-before-completion |
| 大任务并行 | writing-plans → subagent-driven-development → requesting-code-review → verification |
| 收到评审 | receiving-code-review → test-driven-development（补测试）→ verification |
| 分支收尾 | using-git-worktrees / finishing-a-development-branch → verification |

## 冲突时怎么办

技能之间、技能与规则之间冲突时，按 `AGENTS.md` 第 2 节优先级表裁决。
**任何技能都不能覆盖宪法原则三（证据先于结论）。**

## 没有匹配技能时

不要即兴发明流程。回退到 `harness/workflow/protocol.md` 的 O→P→A→V→R，
并在任务结束后判断：这次的套路值得沉淀吗？值得 → 用 `writing-skills` 新增一个。

## 退出标准

- [ ] 已确认命中的技能（或明确说明"无匹配，走 OPAVR"）
- [ ] 已读该技能的 SKILL.md，而不是凭记忆
- [ ] 知道本任务的验收方式与验证命令

## 反模式

- 跳过索引直接改代码
- 读了技能但不执行它的退出标准
- 同时套用两个互相冲突的流程，且不自知
- 凭"我以前这么干过"替代项目里的技能
