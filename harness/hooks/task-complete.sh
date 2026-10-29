#!/usr/bin/env bash
# 任务结束钩子：强制走完验证与记录，防止"声称完成"。
# 关键点：区分 verify.sh 的三态，绝不把 exit 2（无法验证）说成"通过"。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1

echo "=== 交付前闸门 ==="
echo

echo "[1/3] 运行验证回路"
bash scripts/verify.sh
status=$?
echo

case "$status" in
  0)
    echo "  验证结果: 通过（至少一个阶段真实执行且全绿）"
    ;;
  2)
    echo "  验证结果: 无法验证 —— 所有阶段被跳过（未安装依赖或未接入脚本）。" >&2
    echo "  任务状态是「未完成」。禁止表述为通过；请先接入检查后重跑。" >&2
    exit 2
    ;;
  *)
    echo "  验证结果: 失败 (exit ${status})" >&2
    echo "  不得声称完成。先修复失败项再重新执行本钩子。" >&2
    exit 1
    ;;
esac
echo

echo "[2/3] Definition of Done 自查"
echo "  逐项核对 harness/gates/definition-of-done.md，未满足项必须如实列出。"
echo "  验证输出请写入 openspec/changes/<id>/verification.md"
echo

echo "[3/3] 汇报格式"
cat <<'EOF'
  变更：openspec/changes/<id>
  改动：<文件列表 + 各自职责>
  验证：<verify.sh 真实输出摘要 + 退出码>
  遗留：<未做的事 / 已知风险 / 建议后续变更>
EOF
echo
echo "提醒：架构有变化请同步 harness/context/architecture.md；重要取舍请写 docs/decisions/。"
