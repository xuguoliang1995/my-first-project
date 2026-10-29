---
description: 把已澄清的变更拆成可验证的原子任务
---

# /plan

按 `skills/writing-plans/SKILL.md` 执行：

1. 读 `openspec/changes/<id>/proposal.md` 与 delta spec，确认验收点
2. 先写验收，再写任务；按**能力**分组（契约 → 实现 → 接入 → 收尾）
3. 每条任务写：做法一句话 + 验证命令一句话 + checkbox
4. 标出风险与需要用户决策的点
5. 写入 `tasks.md`，用 `npx openspec status --change <id>` 确认产物齐全

任务不合格的判据：一个会话做不完 / diff > 400 行 / 没有验证方式 / 不能独立回滚。
不满足就继续拆。

输出：任务数 + 前三个任务 + 风险清单。
