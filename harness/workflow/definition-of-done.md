# 完成的定义（Definition of Done）

> 这是一道**闸门**，不是建议清单。任何一项未满足，任务状态就是「未完成」，
> 不允许用「基本完成」「只剩一点」之类的表述交付。

## 一、规约层

- [ ] 存在对应的 `openspec/changes/<id>/proposal.md`，写清意图、范围与非目标
- [ ] 行为变化已写进 delta spec（`changes/<id>/specs/<domain>/spec.md`）
- [ ] 每个 `Requirement` 至少有一个 `Scenario`，且可被测试验证
- [ ] `npx openspec validate --strict` 通过
- [ ] 非目标（Out of scope）明确列出，防止范围蔓延

## 二、实现层

- [ ] 有对应的测试，且**先看到它失败过**
- [ ] 覆盖正常路径、边界值、错误路径
- [ ] 没有 `any`、没有吞掉的异常、没有调试残留
- [ ] 没有超出变更范围的改动（`git diff` 逐行确认）
- [ ] 依赖方向正确（`apps/* → packages/shared`，未反向）

## 三、验证层

- [ ] `bash scripts/verify.sh` **退出码为 0**（退出码 2 = 无法验证，视为未完成）
- [ ] 输出已写入 `openspec/changes/<id>/verification.md`（含命令与原文摘要）
- [ ] 若某项无法验证，明确标注「未验证」并说明原因
- [ ] 汇报中贴出的是输出摘要，不是转述

## 四、记录层

- [ ] `tasks.md` 中相关任务已勾选
- [ ] 架构有变化 → `harness/context/architecture.md` 已更新
- [ ] 有重要取舍 → `docs/decisions/` 有 ADR
- [ ] 新术语 → `harness/context/glossary.md` 已登记

## 五、交付层

- [ ] 提交信息符合 Conventional Commits，并引用变更 id
- [ ] 变更已 `openspec archive` 归档，或明确保留待续
- [ ] 汇报四项齐全：变更 / 改动 / 验证 / 遗留

## 快速自检：三个致命问题

1. **如果有人现在回滚这个提交，会不会破坏别的东西？** 会 → 拆分不够
2. **三个月后的人能只看仓库就知道为什么这么改吗？** 不能 → 记录缺失
3. **我能把验证输出原样贴出来吗？** 不能 → 其实没验证
