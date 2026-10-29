#!/usr/bin/env bash
# 会话开始钩子：注入必读清单、技能索引、进行中变更与仓库健康快照。
# 目的：让智能体不必从零猜项目状态，也避免"有技能却不知道"的退化。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1

echo "=== my-first-project / session start ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo

echo "-- 必读顺序 --"
echo "1. harness/rules/00-constitution.md"
echo "2. harness/context/architecture.md"
echo "3. openspec/project.md"
echo "4. openspec/changes/<id>/proposal.md（进行中的变更）"
echo "5. skills/<命中>/SKILL.md"
echo

echo "-- 技能索引（不确定用哪个，先读 skills/using-skills/SKILL.md）--"
if [ -d skills ]; then
  find skills -mindepth 2 -maxdepth 2 -name SKILL.md | sort | sed 's|^|  |'
else
  echo "  (skills/ 不存在)"
fi
echo

echo "-- 进行中的变更 --"
active="$(find openspec/changes -mindepth 1 -maxdepth 1 -type d ! -name archive ! -name '_*' 2>/dev/null || true)"
if [ -n "$active" ]; then
  echo "$active" | sed 's|^|  |'
else
  echo "  (无) 非琐碎改动请先执行: bash scripts/new-change.sh <id>"
fi
echo

echo "-- 已登记的规约域 --"
domains="$(find openspec/specs -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)"
if [ -n "$domains" ]; then
  echo "$domains" | sed 's|^|  |'
else
  echo "  (空) openspec/specs 尚无规约，说明系统行为尚未被记录"
fi
echo

echo "-- 工作区状态 --"
if git rev-parse --git-dir > /dev/null 2>&1; then
  dirty="$(git status --porcelain -uall | wc -l | tr -d ' ')"
  if git rev-parse --verify HEAD > /dev/null 2>&1; then
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  else
    branch="(尚无提交，HEAD 未指向任何 commit)"
  fi
  echo "  分支: ${branch}   未提交改动: ${dirty} 个文件"
  if [ -x .git/hooks/pre-commit ]; then
    echo "  pre-commit 闸门: 已接线"
  else
    echo "  pre-commit 闸门: 未接线（执行 bash scripts/install-hooks.sh）"
  fi
else
  echo "  (非 git 仓库)"
fi
echo "======================================="
