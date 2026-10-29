---
description: 走完交付前闸门：验证、DoD 自查、证据落档
---

# /verify

执行 `bash harness/hooks/task-complete.sh`，然后按 `skills/verification-before-completion/SKILL.md` 处理：

1. 读 `verify.sh` 的真实输出，按退出码分流
   - **0** → 通过
   - **1** → 逐条列出失败项，修复后重跑（禁止改断言/跳过）
   - **2** → 无法验证：说明缺什么（依赖/脚本），**不得**表述为完成
2. 逐项对照 `harness/gates/definition-of-done.md`，未满足项如实列出
3. 把输出写入 `openspec/changes/<id>/verification.md`
4. 按四项格式汇报：变更 / 改动 / 验证 / 遗留

未验证项必须显式标注，不许用"应该没问题"代替。
