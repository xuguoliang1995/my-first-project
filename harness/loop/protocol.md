# 智能体循环协议

> Harness 的核心不是"更强的模型"，而是**一个不允许自欺的闭环**。
> 每一次任务都按 O→P→A→V→R 走完，任何一步缺失都视为任务未完成。
> 与 `AGENTS.md` 第 6 节的七步工作流一一对应。

## 循环总览

```
Observe ──► Plan ──► Act ──► Verify ──► Record
   ▲                                     │
   └──────────── 失败则回到 Observe/Plan ──┘
```

## O — Observe（观察）

- 读 `harness/rules/00-constitution.md`
- 读 `harness/context/architecture.md` 与 `openspec/project.md`
- 找到相关 `openspec/specs/<domain>/spec.md` 与当前变更 `proposal.md`
- 用搜索而非猜测定位代码：先搜符号，再读文件，再改
- **退出条件**：能用自己的话复述"现在的行为是什么、我要改的是哪一部分"

若无法复述 → 回到用户提问，不要开始写代码。

## P — Plan（计划）

- 判断命中哪个技能（`AGENTS.md` 第 5 节索引），读对应 `SKILL.md`
- 把目标拆成可独立验证的原子任务，每个任务写清**怎么验证**
- 单任务粒度：一个会话内可完成、diff 不超过 400 行
- 需要技术选型时，先出 2-3 个候选与取舍，再决定
- **退出条件**：`tasks.md` 里每一行都有 checkbox 和验证方式

## A — Act（执行）

- 严格按任务顺序，一次一个
- 改代码前先写会失败的测试（`skills/test-driven-development`）
- 只改任务范围内涉及的文件；发现范围外问题 → 记录，不顺手改
- 每个任务完成立即勾选 checkbox，不要攒到最后

## V — Verify（验证）

- 跑 `bash scripts/verify.sh`，按退出码分流：

| 退出码 | 含义 | 处理 |
| --- | --- | --- |
| 0 | 真实执行且全绿 | 可进入 Record |
| 1 | 有失败项 | 回到 A 修复，**不得**改断言或注释测试 |
| 2 | 无法验证（全部跳过） | 补上检查或如实标注「未验证」，**禁止**表述为完成 |

- 单点修复超过 3 轮仍失败 → 停下来说明卡点，请求协助（禁止硬试）
- 结果写入 `openspec/changes/<id>/verification.md`

## R — Record（记录）

- 变更归档：`npx openspec archive <id> -y`（delta 自动合并进 `openspec/specs/`）
- 架构有变：更新 `harness/context/architecture.md`
- 重要取舍：写 `docs/decisions/NNNN-*.md`
- 踩坑与反模式：写 `docs/retro/`
- 新术语：登记到 `harness/context/glossary.md`

## 冲突与例外处理

| 情况 | 处理 |
| --- | --- |
| 用户指令与规则冲突 | 按 `AGENTS.md` 第 2 节优先级表裁决，并在汇报中指出违反了哪条 |
| 需求自相矛盾 | 停下提问，不要自行裁决 |
| 无法验证（缺环境/缺依赖） | 明确说明"未验证"及原因，不得表述为"完成" |
| 执行中发现方案不可行 | 回到 P，更新 `design.md`，说明为何改方案 |
| 任务中途被打断 | 在 `tasks.md` 记录已完成的勾选与下一步，便于续接 |

## 反自欺检查（每次汇报前自问）

1. 我贴的是**命令输出**，还是我的**总结**？
2. 我有没有为"通过"而放宽任何断言或配置？
3. 我改动的文件里，有没有任务范围之外的部分？
4. 我说"已完成"的每一项，都有对应的验证结果吗？
