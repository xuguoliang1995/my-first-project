#!/usr/bin/env bash
# 验证回路：类型检查 → 静态检查 → 测试 → 构建，逐个工作区包执行。
#
# 三态退出码（本脚本的核心契约）：
#   0 = 至少一个阶段真实执行且全部通过
#   1 = 存在失败项
#   2 = 无法验证（所有阶段被跳过 / 未安装依赖）—— 不等于通过
#
# 设计要点：
#   1. 不依赖包管理器 —— 直接读取各包 package.json 的 scripts 并执行
#   2. 不因首个失败就中断 —— 汇总全部失败项，一次性暴露问题
#   3. 缺省阶段明确标记"跳过"，避免把"没跑"误认为"通过"
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# 让子包脚本能找到根 node_modules/.bin（tsc 等），不依赖包管理器
export PATH="$ROOT/node_modules/.bin:$PATH"

STAGES=(typecheck lint test build)
FAILED=""
PASSED=0
SKIPPED=0

read_pkg_field() {
  node --input-type=commonjs -e '
    const fs = require("fs");
    const [file, field] = process.argv.slice(1);
    try {
      const pkg = JSON.parse(fs.readFileSync(file, "utf8"));
      const value = field.split(".").reduce((acc, k) => (acc == null ? undefined : acc[k]), pkg);
      if (typeof value === "string") process.stdout.write(value);
    } catch {
      process.exit(0);
    }
  ' "$1" "$2" 2>/dev/null
}

collect_packages() {
  node --input-type=commonjs -e '
    const fs = require("fs");
    const path = require("path");
    const roots = ["apps", "packages"];
    const found = [];
    for (const root of roots) {
      if (!fs.existsSync(root)) continue;
      for (const entry of fs.readdirSync(root)) {
        const pkgPath = path.join(root, entry, "package.json");
        if (fs.existsSync(pkgPath)) found.push(path.dirname(pkgPath));
      }
    }
    if (found.length === 0) process.stdout.write("ROOT_ONLY");
    else process.stdout.write(found.join("\n"));
  ' 2>/dev/null
}

PACKAGES="$(collect_packages)"
[ -z "$PACKAGES" ] && PACKAGES="ROOT_ONLY"

echo "=== verify: my-first-project ==="
echo "阶段: spec ${STAGES[*]}"
echo "包:   $(echo "$PACKAGES" | tr '\n' ' ')"
echo

# 意图层校验：openspec 结构是否合法（变更/规约能否被 CLI 正确解析）。
# 必须带 --no-interactive，否则在无 TTY 环境下会等待交互输入而挂起。
echo "-- spec ------------------------------------------------------"
if command -v openspec >/dev/null 2>&1; then
  echo "   \$ openspec validate --strict --no-interactive --all"
  if openspec validate --strict --no-interactive --all < /dev/null; then
    echo "   ^ 规约结构合法"
  else
    FAILED="${FAILED}(root):spec\n"
    echo "   ^ 失败: openspec 规约结构不合法" >&2
  fi
else
  SKIPPED=$((SKIPPED + 1))
  echo "   跳过（未安装 openspec CLI：先 npm install）"
fi
echo

for stage in "${STAGES[@]}"; do
  echo "-- ${stage} -------------------------------------------------"
  ran_in_stage=0

  for pkg in $PACKAGES; do
    if [ "$pkg" = "ROOT_ONLY" ]; then
      pkg_dir="."
      pkg_json="./package.json"
    else
      pkg_dir="$pkg"
      pkg_json="$pkg/package.json"
    fi

    command_str="$(read_pkg_field "$pkg_json" "scripts.$stage")"
    if [ -z "$command_str" ]; then
      continue
    fi

    ran_in_stage=1
    echo "   [$pkg_dir] $ $command_str"
    if ( cd "$pkg_dir" && eval "$command_str" ); then
      PASSED=$((PASSED + 1))
    else
      FAILED="${FAILED}${pkg_dir}:${stage}\n"
      echo "   ^ 失败: ${pkg_dir} / ${stage}" >&2
    fi
  done

  if [ "$ran_in_stage" -eq 0 ]; then
    SKIPPED=$((SKIPPED + 1))
    echo "   跳过（没有包定义 \"${stage}\" 脚本）"
  fi
  echo
done

echo "=== 汇总 ==="
echo "通过: ${PASSED}   跳过阶段: ${SKIPPED}"
echo

if [ -n "$FAILED" ]; then
  echo "失败:"
  printf "   - %b" "$FAILED"
  echo
  echo "结论: 验证失败（exit 1），不得声称完成。先修复上述项再重跑。"
  exit 1
fi

if [ "$PASSED" -eq 0 ]; then
  echo "结论: 无法验证（exit 2）——所有阶段均被跳过。"
  echo "      常见原因：未安装依赖（npm install）或包未定义 typecheck/test 脚本。"
  echo "      这不等于通过，任务状态是「未完成」。"
  exit 2
fi

echo "结论: 验证通过（exit 0）。"
exit 0
