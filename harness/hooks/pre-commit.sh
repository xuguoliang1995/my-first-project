#!/usr/bin/env bash
# git pre-commit 闸门：把"提交前必须验证"从自觉变成不可绕过。
# 由 scripts/install-hooks.sh 安装到 .git/hooks/pre-commit。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1

staged="$(git diff --cached --name-only --diff-filter=ACM)"

# 1. 密钥与 .env 永不入库
if printf '%s\n' "$staged" | grep -qE '(^|/)\.env($|\.)'; then
  echo "[pre-commit] 拒绝：暂存区包含 .env 文件。凭据只能走环境变量。" >&2
  exit 1
fi
if printf '%s\n' "$staged" | grep -qE '\.(pem|key)$'; then
  echo "[pre-commit] 拒绝：暂存区包含证书/私钥文件。" >&2
  exit 1
fi

# 2. 调试残留
if printf '%s\n' "$staged" | grep -qE '\.(ts|tsx|js|jsx|mjs|cjs)$'; then
  hits="$(git diff --cached -U0 -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.mjs' '*.cjs' \
    | grep -nE '^\+.*(debugger|console\.log)' || true)"
  if [ -n "$hits" ]; then
    echo "[pre-commit] 拒绝：暂存区包含调试残留：" >&2
    echo "$hits" >&2
    exit 1
  fi
fi

# 3. 验证回路（三态）
echo "[pre-commit] 运行验证回路..."
bash scripts/verify.sh
status=$?

case "$status" in
  0)
    echo "[pre-commit] 通过"
    exit 0
    ;;
  2)
    echo "[pre-commit] 阻断：无法验证（所有阶段被跳过）。" >&2
    echo "            先执行 npm install / 接入 typecheck 脚本，再提交。" >&2
    exit 1
    ;;
  *)
    echo "[pre-commit] 阻断：验证失败 (exit ${status})。修复后重试。" >&2
    exit 1
    ;;
esac
