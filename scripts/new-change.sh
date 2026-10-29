#!/usr/bin/env bash
# 从官方 OpenSpec CLI 创建一个新变更，并打印下一步。
# 用法: bash scripts/new-change.sh <change-id> ["变更标题"]
# 约束: change-id 必须是 kebab-case（官方 CLI 也要求）
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

usage() {
  cat <<'EOF'
用法: bash scripts/new-change.sh <change-id> ["变更标题"]

示例:
  bash scripts/new-change.sh add-hello-endpoint "新增 Hello 接口"
  bash scripts/new-change.sh choose-web-stack "确定前端技术栈"

说明:
  本脚本是 `openspec new change` 的薄封装，保证与官方 CLI 结构一致。
  proposal / specs / design / tasks 的写法用官方指引获取：
    npx openspec instructions proposal --change <id>
EOF
}

if [ "$#" -lt 1 ]; then
  usage >&2
  exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

CHANGE_ID="$1"
CHANGE_TITLE="${2:-$1}"

if ! printf '%s' "$CHANGE_ID" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
  echo "错误: 变更 id 必须为 kebab-case，例如 add-hello-endpoint" >&2
  exit 1
fi

if [ -e "openspec/changes/${CHANGE_ID}" ]; then
  echo "错误: 变更已存在: openspec/changes/${CHANGE_ID}" >&2
  echo "      继续编辑该目录；若已废弃，用 npx openspec archive 或移入 archive/。" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "错误: 未找到 npx，请先安装 Node.js >= 22" >&2
  exit 1
fi

echo "创建变更: ${CHANGE_ID}"
if ! npx openspec new change "$CHANGE_ID" --goal "$CHANGE_TITLE"; then
  echo "错误: openspec new change 失败。先执行 npm install 安装 CLI。" >&2
  exit 1
fi

echo
echo "下一步:"
echo "  1. npx openspec status --change ${CHANGE_ID}      # 看产物完成度"
echo "  2. npx openspec instructions proposal --change ${CHANGE_ID}"
echo "  3. 填写 proposal.md（意图 / 范围 / 非目标），再写 delta spec"
echo "  4. 需要技术方案时补 design.md，并在 docs/decisions/ 写 ADR"
echo "  5. 拆 tasks.md（每条含验证方式）后按 TDD 顺序实现"
echo "  6. bash scripts/verify.sh  → 结果写入 changes/${CHANGE_ID}/verification.md"
