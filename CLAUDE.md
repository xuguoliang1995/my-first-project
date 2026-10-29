# CLAUDE.md

本项目的智能体约定统一维护在 `AGENTS.md`，此处仅做入口转发，避免多份规则漂移。

@AGENTS.md

## Claude Code 补充

- 本仓库的 IDE 集成只维护 `.qoder/`，没有 `.claude/`：技能、命令、钩子不会被 Claude Code 自动发现
- 技能真身在 `skills/`；不确定用哪个时先读 `skills/using-skills/SKILL.md`
- 会话开始先手动执行 `bash harness/hooks/session-start.sh`，获取必读清单与仓库健康快照
- 涉及多步骤任务时先产出计划到 `openspec/changes/<id>/tasks.md`，再执行
- 提交前必须由 `scripts/verify.sh` 输出真实结果；`exit 2` 表示「无法验证」，不得表述为通过
