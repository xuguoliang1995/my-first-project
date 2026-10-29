#!/usr/bin/env bash
# 把 Harness 的钩子与方法层接到真实执行路径上（这是"不可绕过"与"只是文档"的分界线）。
#   1. git pre-commit -> harness/hooks/pre-commit.sh
#   2. 手写技能 skills/<name>/ 逐项链接进 .qoder/skills/
#   3. 校验 .qoder/settings.json 引用的钩子脚本存在且可执行
# 可重复执行（幂等）。
#
# 为什么技能逐项链接而不是整目录链接：
#   `npx openspec init/update` 会往 .qoder/skills/ 写生成文件（openspec-*）。
#   若整目录链接到根 skills/，生成文件会穿透进手写目录，与人写的技能混在一起，
#   且下次 update 时被覆盖的范围无法界定。逐项链接让两类文件物理分离：
#     手写 —— 根 skills/（真身）；.qoder/skills/ 里只是链接
#     生成 —— .qoder/skills/openspec-*、.qoder/commands/opsx/，勿手改
#   .qoder/commands/*.md 与 .qoder/agents/*.md 是手写真身，直接存放，不需要链接。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "错误: 当前目录不是 git 仓库" >&2
  exit 1
fi

chmod +x harness/hooks/*.sh scripts/*.sh 2>/dev/null || true

BROKEN=0

# 符号链接的相对路径以「链接所在目录」为基准，而不是仓库根。
# 所以必须按链接深度算 ../ 的层数，并在创建后检查链接确实能打开。
check_link() {
  local link="$1"
  if [ -e "$link" ]; then
    echo "已接线: ${link} -> $(readlink "$link")"
  else
    echo "错误: ${link} 是断链（-> $(readlink "$link")）" >&2
    BROKEN=1
  fi
}

# 创建或刷新一个链接；目标位置已有非链接实体时不覆盖（可能是生成文件或人工文件）。
make_link() {
  local target="$1" link="$2"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "警告: ${link} 已存在且不是符号链接，跳过（请人工确认）" >&2
    return
  fi
  ln -sfn "$target" "$link"
  check_link "$link"
}

# 1. git pre-commit（.git/hooks/ 深两层 → ../../）
HOOK_DST=".git/hooks/pre-commit"
if [ -e "$HOOK_DST" ] && [ ! -L "$HOOK_DST" ]; then
  echo "警告: .git/hooks/pre-commit 已存在且不是符号链接，跳过（请人工合并）" >&2
else
  ln -sfn "../../harness/hooks/pre-commit.sh" "$HOOK_DST"
  check_link "$HOOK_DST"
fi

# 2. 手写技能：逐项链接（.qoder/skills/<name> 深两层 → ../../）
if [ -L .qoder/skills ]; then
  echo "错误: .qoder/skills 是整目录链接（旧布局），请先解除该链接本身（不影响目标目录）后重跑：" >&2
  echo "      unlink .qoder/skills" >&2
  BROKEN=1
else
  mkdir -p .qoder/skills
  for dir in skills/*/; do
    name="$(basename "$dir")"
    [ -f "skills/${name}/SKILL.md" ] || continue
    make_link "../../skills/${name}" ".qoder/skills/${name}"
  done
fi

# 已删除的手写技能会留下断链，在这里一并暴露
for link in .qoder/skills/*; do
  if [ -L "$link" ] && [ ! -e "$link" ]; then
    echo "错误: ${link} 是断链（源已删除？）-> $(readlink "$link")" >&2
    BROKEN=1
  fi
done

# 3. IDE 钩子：settings.json 里引用的脚本必须存在且可执行
if [ -f .qoder/settings.json ]; then
  for script in $(grep -oE 'harness/hooks/[A-Za-z0-9_.-]+\.sh' .qoder/settings.json | sort -u); do
    if [ -x "$script" ]; then
      echo "已接线: .qoder/settings.json -> ${script}"
    else
      echo "错误: .qoder/settings.json 引用的 ${script} 不存在或不可执行" >&2
      BROKEN=1
    fi
  done
fi

if [ "$BROKEN" -ne 0 ]; then
  echo "结论: 接线失败，存在断链或旧布局（exit 1）。" >&2
  exit 1
fi

echo
echo "完成。验证方式："
echo "  bash harness/hooks/session-start.sh    # 应打印必读清单与技能索引"
echo "  git commit 会先跑 scripts/verify.sh（退出码 2 也会阻断）"
echo "  修改 .qoder/settings.json 后需重启 Qoder IDE 才生效（不支持热加载）"
