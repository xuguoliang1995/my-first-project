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
# 与 SKIPPED 不同：UNVERIFIED 表示"该阶段本应验证，但缺少工具链/产物而无法验证"，
# 它绝不能等价于通过——只要它非 0，最终退出码就必须是 2。
UNVERIFIED=0

# JDK 探测：非登录 shell（如 CI、直接 bash 脚本）拿不到 shell rc 里的 JAVA_HOME，
# 这里补一层兜底，避免把"环境没配好"误报成"代码有问题"。
if [ -z "${JAVA_HOME:-}" ] && command -v /usr/libexec/java_home >/dev/null 2>&1; then
  detected_jdk="$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
  [ -n "$detected_jdk" ] && export JAVA_HOME="$detected_jdk"
fi
if [ -n "${JAVA_HOME:-}" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
  export PATH="${JAVA_HOME}/bin:$PATH"
fi

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

# -- maven ------------------------------------------------------
# 后端不是 npm 包，单独一段。用 wrapper 执行，不要求全局 mvn；但必须有 JDK。
echo "-- maven -----------------------------------------------------"
if [ -f apps/api/pom.xml ]; then
  # 注意：macOS 的 /usr/bin/java 是存根，存在但执行失败，
  # 因此必须真实执行一次而不能只靠 command -v。
  if java -version >/dev/null 2>&1; then
    if [ -x apps/api/mvnw ]; then
      echo "   [apps/api] \$ ./mvnw -q test"
      if ( cd apps/api && ./mvnw -q test ); then
        PASSED=$((PASSED + 1))
      else
        FAILED="${FAILED}apps/api:maven\n"
        echo "   ^ 失败: apps/api / maven test" >&2
      fi
    else
      UNVERIFIED=$((UNVERIFIED + 1))
      echo "   无法验证（apps/api/mvnw 缺失或没有执行位）" >&2
    fi
  else
    UNVERIFIED=$((UNVERIFIED + 1))
    echo "   无法验证（未找到 JDK：java 不在 PATH 且 JAVA_HOME 不可用）" >&2
  fi
else
  echo "   跳过（未检测到 apps/api/pom.xml）"
fi
echo

# -- contract ---------------------------------------------------
# 契约一致性：contracts/openapi.json 是真相，前端生成类型必须与它同步。
# 做法是重新生成一次再比对哈希——不一致说明有人改了契约却没重跑 codegen。
echo "-- contract --------------------------------------------------"
if [ -f contracts/openapi.json ] && [ -f apps/web/package.json ] && [ -f apps/web/src/api/schema.d.ts ]; then
  if command -v npm >/dev/null 2>&1; then
    contract_before="$(shasum apps/web/src/api/schema.d.ts | awk '{print $1}')"
    echo "   \$ npm run codegen --workspace apps/web"
    if npm run codegen --workspace apps/web >/dev/null 2>&1; then
      contract_after="$(shasum apps/web/src/api/schema.d.ts | awk '{print $1}')"
      if [ "$contract_before" = "$contract_after" ]; then
        PASSED=$((PASSED + 1))
        echo "   ^ 前端生成类型与 contracts/openapi.json 一致"
      else
        FAILED="${FAILED}(root):contract\n"
        echo "   ^ 失败: 生成类型与契约不一致——重跑 codegen 并提交，或确认契约变更已评审" >&2
      fi
    else
      FAILED="${FAILED}(root):contract\n"
      echo "   ^ 失败: codegen 执行失败" >&2
    fi
  else
    UNVERIFIED=$((UNVERIFIED + 1))
    echo "   无法验证（未找到 npm）" >&2
  fi
else
  UNVERIFIED=$((UNVERIFIED + 1))
  echo "   无法验证（缺少 contracts/openapi.json 或 apps/web/src/api/schema.d.ts）" >&2
fi
echo

echo "=== 汇总 ==="
echo "通过: ${PASSED}   跳过阶段: ${SKIPPED}   无法验证: ${UNVERIFIED}"
echo

if [ -n "$FAILED" ]; then
  echo "失败:"
  printf "   - %b" "$FAILED"
  echo
  echo "结论: 验证失败（exit 1），不得声称完成。先修复上述项再重跑。"
  exit 1
fi

# 有关键阶段"本应验证却无法验证"时，即使其他阶段通过也不能判绿灯。
if [ "$UNVERIFIED" -gt 0 ]; then
  echo "结论: 无法完全验证（exit 2）——有 ${UNVERIFIED} 个阶段因缺少工具链/产物被跳过。"
  echo "      这不等于通过：请补齐环境（如 JDK、npm install）后重跑。"
  exit 2
fi

if [ "$PASSED" -eq 0 ]; then
  echo "结论: 无法验证（exit 2）——所有阶段均被跳过。"
  echo "      常见原因：未安装依赖（npm install）或包未定义 typecheck/test 脚本。"
  echo "      这不等于通过，任务状态是「未完成」。"
  exit 2
fi

echo "结论: 验证通过（exit 0）。"
exit 0
