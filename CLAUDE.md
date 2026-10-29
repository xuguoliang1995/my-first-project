# CLAUDE.md

本项目的智能体约定统一维护在 `AGENTS.md`，此处仅做入口转发，避免多份规则漂移。

@AGENTS.md

## Claude Code 补充

- 项目技能位于 `skills/`，已通过 `.claude/skills` 符号链接注册；不确定用哪个时先读 `skills/using-skills/SKILL.md`
- 会话开始钩子见 `.claude/settings.json`，会打印进行中的变更与仓库健康快照
- 涉及多步骤任务时先产出计划到 `docs/plans/` 或 `openspec/changes/<id>/tasks.md`，再执行
- 提交前必须由 `scripts/verify.sh` 输出真实结果；`exit 2` 表示「无法验证」，不得表述为通过
