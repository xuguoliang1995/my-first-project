#!/usr/bin/env bash
# Qoder PreToolUse(Bash) 闸门：拦截绕过验证与改写远端历史的命令。
# 由 .qoder/settings.json 调用；exit 2 = 阻断，stderr 作为理由反馈给智能体。
set -uo pipefail

input="$(cat)"

if ! command -v jq > /dev/null 2>&1; then
  echo "[guard-bash] 缺少 jq，无法检查命令，已阻断。安装 jq 后重试。" >&2
  exit 2
fi

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

# 1. 跳过 pre-commit 闸门（R-4：不跳验证）
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+commit([[:space:]].*)?[[:space:]](--no-verify|-n)([[:space:]]|$)'; then
  echo "[guard-bash] 拒绝：禁止 git commit --no-verify / -n（AGENTS.md R-4）。verify.sh 失败就修。" >&2
  exit 2
fi

# 2. 强推（含 --force-with-lease）
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push([[:space:]].*)?[[:space:]](--force[a-z-]*|-f)([[:space:]]|$)'; then
  echo "[guard-bash] 拒绝：禁止 git push --force / -f。需要改写远端历史请先征得用户明确同意并由用户执行。" >&2
  exit 2
fi

exit 0
