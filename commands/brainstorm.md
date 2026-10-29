---
description: 澄清一个模糊需求，产出 openspec 变更提案
---

# /brainstorm

按 `skills/brainstorming/SKILL.md` 执行：

1. 复述需求 + 列出你的假设，请用户纠正
2. 搜索现有代码与规约，说明当前行为
3. **一次只问一个问题**，直到能回答：做什么 / 不做什么 / 怎么算做完
4. 给 2-3 个方案，每个写清代价与放弃它失去什么
5. 用户确认后，用 `bash scripts/new-change.sh <id> "<标题>"` 建变更，填写 `proposal.md`

**到此为止，不写实现代码。**

输出：变更 id + proposal 摘要 + 仍需用户决定的问题（如有）。
