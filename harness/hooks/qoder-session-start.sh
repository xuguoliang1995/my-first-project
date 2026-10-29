#!/usr/bin/env bash
# Qoder SessionStart 适配：把 session-start.sh 的文本输出包成 Qoder 要求的 JSON，
# 以 additionalContext 注入会话。由 .qoder/settings.json 调用。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Qoder 通过 stdin 传入事件 JSON，这里用不到，但必须读完
cat > /dev/null

if ! command -v jq > /dev/null 2>&1; then
  echo "[session-start] 缺少 jq，无法注入上下文" >&2
  exit 0
fi

bash "$ROOT/harness/hooks/session-start.sh" 2>&1 \
  | jq -Rs '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: .}}'
