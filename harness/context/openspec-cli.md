# OpenSpec 工具链使用说明

> 讲**怎么用 OpenSpec**（命令、目录、踩过的坑）。项目约定在 `openspec/config.yaml`，
> 任务套路在 `skills/`。结构判据以官方 CLI `@fission-ai/openspec` 为准。
>
> 为什么不放在 `openspec/AGENTS.md`：该文件名被官方视为自己管理的遗留文件，
> 每次 `openspec init` / `openspec update` 都会**无提示删除**（1.15.0 实测）。

## 目录约定

```
openspec/
├── config.yaml              # schema + context / rules / operations（项目约定唯一存放处）
├── specs/<capability>/      # 真相来源：系统当前行为（## Purpose + ## Requirements）
└── changes/
    ├── <change-id>/         # 进行中的变更
    │   ├── .openspec.yaml   # CLI 生成的元数据（勿手写）
    │   ├── proposal.md      # 意图 / 范围 / 非目标
    │   ├── specs/<capability>/spec.md   # delta
    │   ├── design.md
    │   ├── tasks.md
    │   └── verification.md  # 本项目追加：验证证据落档
    └── archive/             # 已归档（自动加 YYYY-MM-DD- 前缀）
```

## 两套入口

| 入口 | 给谁用 | 例子 |
| --- | --- | --- |
| `/opsx:*` 斜杠命令 | AI 助手，在对话中推进变更 | `/opsx:propose 新增健康检查接口` |
| `npx openspec ...` CLI | 人、脚本、`verify.sh` | `npx openspec validate --strict --no-interactive --all` |

`/opsx:*` 内部调用 CLI，两者产出完全一致。

### `/opsx:*`（core 档，已安装）

| 命令 | 作用 | 对应七步 |
| --- | --- | --- |
| `/opsx:explore` | 探索模式：想清楚问题与需求，不产出文件 | 1 澄清 |
| `/opsx:propose` | 一次生成 proposal + specs + design + tasks | 2-4 |
| `/opsx:apply` | 按 tasks.md 实现 | 5 测试先行 |
| `/opsx:update` | 修订规划产物并保持一致，**不改代码** | 中途变更 |
| `/opsx:sync` | delta 合并进主 spec，但不归档 | — |
| `/opsx:archive` | 归档并合并 delta | 7 归档 |

扩展档（`new` / `continue` / `ff` / `verify` / `bulk-archive` / `onboard`）未安装。
启用方式是 `npx openspec config profile`，**这会修改用户级全局配置**
（`~/.config/openspec/config.json`），影响本机所有项目，需人工决定。

## 生成文件（勿手改）

`.claude/skills/openspec-*`、`.claude/commands/opsx/`、`.qoder/skills/openspec-*`、
`.qoder/commands/opsx/` 由 `npx openspec init` / `update` 生成。手改会在下次 update 时被覆盖。
需要定制行为时改 `openspec/config.yaml` 的 `rules` / `operations`。

升级 CLI 后刷新：

```bash
npm install @fission-ai/openspec@latest -D
npx openspec update
bash scripts/install-hooks.sh   # 重新校验手写技能的链接
```

## CLI 速查与已验证的行为

```bash
bash scripts/new-change.sh <id> "标题"              # = npx openspec new change <id> --goal ...
npx openspec status --change <id>                    # 产物完成度与依赖阻塞
npx openspec instructions <artifact> --change <id>   # 官方写作指引（已注入 config.yaml）
npx openspec validate --strict --no-interactive --all
npx openspec archive <id> -y
```

以下均为 1.15.0 实测：

1. `validate` 不带 `--no-interactive` 在无 TTY 环境挂起；该参数**只属于 validate**，
   加在 `list` / `status` 上报 `unknown option`
2. 每条 `### Requirement:` 至少一个 `#### Scenario:`，缺了是 ERROR（exit 1）
3. 需求正文缺 `MUST` / `SHALL` 是 WARNING
4. 纯文档 / 工具链变更没有 delta 会报 `must have at least one delta`——
   在变更的 `.openspec.yaml` 中设置 `skip_specs: true`
5. archive 新建的主 spec 带占位 `Purpose: TBD - created by archiving change <id>`，必须改写
6. 不要手工搬目录到 archive/，否则主 spec 不会更新
7. `init --language` 不会覆盖已有的 config.yaml；语言要求写在 `context` 里
8. 首次 `openspec update` 会改写**用户级**全局配置：把隐式默认的 `core` 迁移为
   显式 `profile: custom` + 同样 6 个 workflows（输出 `Migrated: custom profile`），功能等价
9. `openspec update` 只刷新它自己生成的文件，不会动 `.claude/` `.qoder/` 里的手写技能链接

## delta 书写格式

```markdown
## ADDED Requirements

### Requirement: 任务创建
系统 SHALL 在接受合法输入后创建一条任务记录。

#### Scenario: 合法输入
- **WHEN** 已登录用户提交标题与截止日期
- **THEN** 返回 201 且任务可被查询到

## MODIFIED Requirements

### Requirement: 任务列表分页
（完整的新需求正文 + 所有保留的 Scenario）

## REMOVED Requirements

### Requirement: 旧版导出
（移除原因，以及用户的替代路径）
```

## 与 Harness 的交接点

| 时机 | 动作 |
| --- | --- |
| 变更创建后 | 读 `harness/rules/00-constitution.md` 与命中的 `skills/*/SKILL.md` |
| 实现完成 | 跑 `bash scripts/verify.sh`，结果写入 `verification.md` |
| 归档前 | 对照 `harness/gates/definition-of-done.md` 逐项自查 |
| 归档后 | 改写主 spec 的 Purpose；架构有变则更新 `harness/context/architecture.md` |
