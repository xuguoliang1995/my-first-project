# OpenSpec 工作流（本目录的操作说明）

> 本文件只讲**怎么用 OpenSpec**。项目级规则见 `harness/`，任务套路见 `skills/`。
> 结构判据以官方 CLI 为准：`@fission-ai/openspec`（见 `package.json`）。

## 目录约定

```
openspec/
├── config.yaml              # schema: spec-driven（CLI 据此定位）
├── project.md               # 跨变更稳定的项目约定
├── specs/<capability>/      # 真相来源：系统当前行为
│   └── spec.md              # ## Purpose + ## Requirements
└── changes/
    ├── <change-id>/         # 一个进行中的变更
    │   ├── .openspec.yaml   # CLI 生成的元数据（勿手写）
    │   ├── proposal.md      # 意图 / 范围 / 非目标
    │   ├── specs/<capability>/spec.md   # delta：ADDED/MODIFIED/REMOVED/RENAMED
    │   ├── design.md        # 可选，全量规格时必需
    │   ├── tasks.md         # 原子任务，每条含验证方式
    │   └── verification.md  # 本项目追加：验证证据落档
    └── archive/             # 已归档变更（archive 时自动加日期前缀）
```

## 三个动作

### 1. 新建变更

```bash
bash scripts/new-change.sh add-hello-endpoint "新增 Hello 接口"
# 等价于：npx openspec new change add-hello-endpoint --goal "..."
npx openspec status --change add-hello-endpoint   # 看产物完成度
npx openspec instructions proposal --change <id>  # 取官方写作指引
```

### 2. 校验结构

```bash
npx openspec validate --strict --no-interactive --all
```

**必须带 `--no-interactive`**：否则在无 TTY 环境（CI / 智能体 shell）会等待交互输入而挂起。
该参数只属于 `validate` 子命令，加在 `list` / `status` 上会报 `unknown option`。

失败时按提示补齐：每个 delta 必须落在 `## ADDED/MODIFIED/REMOVED/RENAMED Requirements` 下，
每个 `### Requirement:` 至少有一个 `#### Scenario:`，且描述中必须出现 RFC 2119 关键词
（`MUST` / `SHALL` / `MUST NOT`），否则 strict 模式报警告。

纯文档 / 工具链类变更不需要 delta（否则报 `must have at least one delta`）——
在该变更的 `.openspec.yaml` 里设置 `skip_specs: true`。

### 3. 归档

```bash
npx openspec archive <change-id> -y
```

归档会把 delta 合并进 `openspec/specs/<capability>/spec.md`，并把变更目录移入
`changes/archive/YYYY-MM-DD-<id>/`。**不要手工搬目录**，否则 specs 不会更新。

新建的主 spec 会带一行占位：`Purpose: TBD - created by archiving change <id>`，
归档后**必须**把 `## Purpose` 改写成真实描述，否则真相来源的第一段就是无效信息。

## delta 书写格式

```markdown
## ADDED Requirements

### Requirement: 任务创建

系统 SHALL 在接受合法输入后创建一条任务记录。

#### Scenario: 合法输入

- GIVEN 用户已登录
- WHEN 提交标题与截止日期
- THEN 返回 201 且任务可被查询到

## MODIFIED Requirements

### Requirement: 任务列表分页

（新的行为描述）

（原行为：固定返回前 20 条）

## REMOVED Requirements

### Requirement: 旧版导出

（移除原因，以及用户的替代路径）
```

主 spec（`specs/<capability>/spec.md`）则由 archive 自动维护：
`## Purpose` + `## Requirements` + 各 `### Requirement:` / `#### Scenario:`。

## 与 Harness 的交接点

| 时机 | 动作 |
| --- | --- |
| 变更创建后 | 读 `harness/rules/00-constitution.md` 与命中的 `skills/*/SKILL.md` |
| 实现完成 | 跑 `bash scripts/verify.sh`，结果写入 `verification.md` |
| 归档前 | 对照 `harness/gates/definition-of-done.md` 逐项自查 |
| 归档后 | 更新 `harness/context/architecture.md`（若架构有变） |
