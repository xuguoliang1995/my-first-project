# AGENTS.md — my-first-project

> 本文件是 AI 编码智能体的**唯一入口**，适用于 Qoder / Claude Code / Cursor / Codex。
> 冲突时的裁决顺序见「2. 优先级」，不要靠猜测。

## 1. 项目是什么

全栈 Web 应用。当前处于**骨架阶段**：固化的只有流程与约束，技术栈刻意未定。
任何 app 的选型都必须走一次 openspec 变更，结论写入 `harness/context/architecture.md`
与 `docs/decisions/`。

## 2. 优先级（唯一裁决表）

从高到低。发生冲突时，按此表裁决并在汇报中写明违反了哪一条：

| 级别 | 来源 | 说明 |
| --- | --- | --- |
| 1 | 用户当前明确指令 | 与规则冲突时**执行用户指令**，但必须显式标注「违反 R-x」 |
| 2 | `harness/rules/00-constitution.md` | 不可协商。用户要求违反时，先给替代方案，不静默执行 |
| 3 | `harness/rules/10/20/30-*.md` | 代码、测试、安全与提交 |
| 4 | `openspec/specs/` 与当前 `changes/<id>/` | 行为真相来源 |
| 5 | `skills/<命中>/SKILL.md` | 方法层 |
| 6 | `docs/decisions/` 与 `harness/context/` | 已固化的决策与架构认知 |
| 7 | 本文件其余章节 | 导航与格式约定 |

**没有任何规则允许「没有验证证据就声称完成」**，即使用户催。

## 3. 必读顺序（按需加载，不要一次全读）

1. `harness/rules/00-constitution.md` — 永远先读
2. `harness/context/architecture.md` — 系统当前长什么样
3. `openspec/config.yaml` — 项目级约定、技术边界、**变更规模判据**（同时被注入到 `/opsx:*` 指引中）
4. `openspec/changes/<id>/proposal.md` — 本次要做什么（有变更时）
5. `skills/<命中>/SKILL.md` — 当前任务套路（索引见第 5 节）
6. 动手改代码前：目标域 `openspec/specs/<domain>/spec.md`
7. 交付前：`harness/gates/definition-of-done.md` + `harness/loop/protocol.md`

## 4. 三层架构

| 层 | 目录 | 回答什么问题 | 变更频率 |
| --- | --- | --- | --- |
| **意图层** — OpenSpec | `openspec/` | 系统**应该**表现成什么样 | 每个需求 |
| **执行层** — Harness | `harness/` | 智能体**如何可靠地**把事做完 | 很少 |
| **方法层** — Superpowers | `skills/` | 这类任务**按什么套路**推进 | 按需增删 |

一句话：**OpenSpec 定义正确性判据，Harness 保证收敛能力，Skills 复用成功路径。**

## 5. 技能索引（先查表，再动手）

| 任务信号 | 技能 |
| --- | --- |
| 需求模糊、有多种解法、要新依赖 | `skills/brainstorming/SKILL.md` |
| 需求已清、要拆成可验证任务 | `skills/writing-plans/SKILL.md` |
| 按计划逐项执行 | `skills/executing-plans/SKILL.md` |
| 任务间无依赖、要并行或隔离上下文 | `skills/subagent-driven-development/SKILL.md` |
| 写任何有分支的逻辑 | `skills/test-driven-development/SKILL.md` |
| 报错、测试失败、行为不符预期 | `skills/systematic-debugging/SKILL.md` |
| 实现完成、提交前 | `skills/requesting-code-review/SKILL.md` |
| 收到评审意见 | `skills/receiving-code-review/SKILL.md` |
| 要说「完成」之前 | `skills/verification-before-completion/SKILL.md` |
| 需要隔离工作区、避免污染主干 | `skills/using-git-worktrees/SKILL.md` |
| 分支收尾、合并、清理 | `skills/finishing-a-development-branch/SKILL.md` |
| 新增或修改技能本身 | `skills/writing-skills/SKILL.md` |
| 不确定该用哪个 | `skills/using-skills/SKILL.md`（元技能） |

OpenSpec 官方技能（`/opsx:*`，由 `npx openspec init` 生成在 `.claude/`、`.qoder/`）负责
**规约产物的创建与归档**；上表的手写技能负责**怎么把事做对**。两者叠加使用，不互相替代。
命令说明见 `harness/context/openspec-cli.md`。

| 任务信号 | OPSX 命令 |
| --- | --- |
| 想法未成形，要先想清楚 | `/opsx:explore` |
| 需求已清，要建变更并生成全部规划产物 | `/opsx:propose` |
| 规划产物齐了，开始实现 | `/opsx:apply` |
| 中途需求变化，要修订规划（不改代码） | `/opsx:update` |
| 实现完成、验证通过，要归档 | `/opsx:archive` |

## 6. 标准工作流（七步 = O→P→A→V→R）

| # | 步骤 | 循环阶段 | 产物 | 手写技能 | OPSX |
| --- | --- | --- | --- | --- | --- |
| 1 | 澄清 | O | 共识 | brainstorming | `/opsx:explore` |
| 2 | 立规约 | P | `changes/<id>/proposal.md` + delta spec | — | `/opsx:propose` |
| 3 | 定方案 | P | `design.md` / ADR | writing-plans | （同上） |
| 4 | 拆任务 | P | `tasks.md`（每条含验证方式） | writing-plans | （同上） |
| 5 | 测试先行 | A | 红灯 → 绿灯 | test-driven-development | `/opsx:apply` |
| 6 | 验证 | V | `changes/<id>/verification.md` 真实输出 | verification-before-completion | — |
| 7 | 归档 | R | 合并 delta 进主 spec | — | `/opsx:archive` |

Lite 路径可跳过第 3 步，**不允许跳过第 2 步和第 6 步**。
第 6 步没有 OPSX 对应：`/opsx:apply` 完成**不等于**验证通过，必须跑 `bash scripts/verify.sh`。

## 7. 硬性规则（违反即返工）

1. **没有 openspec 变更，不改业务代码**。例外：拼写、注释、格式。
2. **测试先行**。先写一个能失败的测试，再写让它通过的代码。
3. **没有验证证据，不得声称完成**。「应该能跑」不是证据。
4. **不跳验证**。`verify.sh` 失败就修，禁止 `--no-verify` / 注释断言。
5. **小步提交**。一次提交一件事，单次改动 > 400 行要拆。
6. **不做未被要求的重构**。发现了记进 `docs/retro/` 或新开变更。
7. **不确定就问**。宁可停下来问，也不要猜着写 200 行。
8. **不写死密钥**。凭据走环境变量，`.env*` 不入库。

## 8. 命令

```bash
bash scripts/install-hooks.sh          # 首次：接线 git pre-commit 闸门
bash scripts/verify.sh                 # 三态验证：0 通过 / 1 失败 / 2 无法验证
bash scripts/new-change.sh <id> [标题]  # 创建 openspec 变更（包装官方 CLI）
npx openspec status --change <id>      # 产物完成度
npx openspec validate --strict --no-interactive --all   # 结构校验（必须带 --no-interactive，否则无 TTY 时挂起）
npx openspec archive <id> -y           # 归档并合并 delta 进主 spec
```

包管理：**npm workspaces**（`npm install`），单一 `package-lock.json`。
`verify.sh` 本身不依赖任何包管理器 —— 它直接读各包 `package.json` 的 scripts 执行。

## 9. 目录地图

```
my-first-project/
├── AGENTS.md                  # 本文件，唯一入口
├── CLAUDE.md                  # 转发到 AGENTS.md
├── harness/                   # ★ 执行层
│   ├── rules/                 # 宪法 / 代码 / 测试 / 安全与提交
│   ├── context/               # 架构全景 / 术语表 / OpenSpec CLI 说明
│   ├── gates/                 # 完成的定义（DoD）
│   ├── loop/                  # O→P→A→V→R 协议
│   └── hooks/                 # session-start / task-complete / pre-commit
├── openspec/                  # ★ 意图层（官方 CLI 兼容）
│   ├── config.yaml            # schema + context / rules / operations（项目约定唯一存放处）
│   ├── specs/<domain>/        # 当前行为的唯一真相来源
│   └── changes/<id>/          # 进行中的变更 + archive/
├── skills/                    # ★ 方法层：手写技能真身（Agent Skills 格式）
├── commands/                  # 手写斜杠命令真身
├── agents/                    # 子智能体定义
├── .claude/ .qoder/           # IDE 集成：手写技能/命令的逐项链接 + openspec 生成文件
│   ├── skills/openspec-*      #   生成，勿手改（npx openspec update 刷新）
│   └── commands/opsx/         #   生成，勿手改
├── docs/{plans,decisions,retro}/
├── apps/{web,api}/            # 可部署单元（待选型）
├── packages/shared/           # 跨端类型与纯函数
└── scripts/                   # verify / new-change / install-hooks
```

## 10. 汇报格式（缺项视为未完成）

```
变更：openspec/changes/<id>
改动：<文件列表 + 各自职责>
验证：<verify.sh 真实输出摘要，失败项必须列出>
遗留：<未做的事 / 已知风险 / 建议后续变更>
```

验证输出**必须同时写入** `openspec/changes/<id>/verification.md`——对话会消失，
文件不会。
