#!/usr/bin/env bash
# 把 Harness 的钩子接到真实执行路径上（这是"不可绕过"与"只是文档"的分界线）。
#   1. git pre-commit  -> harness/hooks/pre-commit.sh
#   2. .claude/skills、.claude/commands、.claude/agents -> 项目根对应目录
# 可重复执行（幂等）。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "错误: 当前目录不是 git 仓库" >&2
  exit 1
fi

chmod +x harness/hooks/*.sh scripts/*.sh 2>/dev/null || true

# 1. git pre-commit
HOOK_SRC="../../harness/hooks/pre-commit.sh"
HOOK_DST=".git/hooks/pre-commit"
if [ -e "$HOOK_DST" ] && [ ! -L "$HOOK_DST" ]; then
  echo "警告: .git/hooks/pre-commit 已存在且不是符号链接，跳过（请人工合并）" >&2
else
  ln -sfn "$HOOK_SRC" "$HOOK_DST"
  echo "已接线: .git/hooks/pre-commit -> harness/hooks/pre-commit.sh"
fi

# 2. .claude 集成目录（避免复制导致的规则漂移）
link_dir() {
  local name="$1"
  local target="../../${name}"
  if [ -d "$name" ]; then
    if [ -e ".claude/${name}" ] && [ ! -L ".claude/${name}" ]; then
      echo "警告: .claude/${name} 已存在且不是符号链接，跳过" >&2
      return
    fi
    ln -sfn "$target" ".claude/${name}"
    echo "已接线: .claude/${name} -> ${name}/"
  fi
}

link_dir skills
link_dir commands
link_dir agents

echo
echo "完成。验证方式："
echo "  bash harness/hooks/session-start.sh    # 应打印必读清单与技能索引"
echo "  git commit 会先跑 scripts/verify.sh（退出码 2 也会阻断）"
