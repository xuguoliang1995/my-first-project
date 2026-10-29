# 真相来源（openspec/specs）

本目录存放系统**当前**行为的规约，按 capability（能力/规约域）分目录：

```
specs/
└── <capability>/
    └── spec.md     # ## Purpose + ## Requirements + ### Requirement: / #### Scenario:
```

规则：

- 这里的内容由 `npx openspec archive <id> -y` 自动合并维护，**不要手工散改**
- 一个 capability 对应一个业务能力（如 `tasks`、`auth`），不按代码目录划分
- 新增 capability 时，先在 `harness/context/glossary.md` 登记术语

当前规约域：

- `health-check/` —— 健康探针接口与前端连通状态展示（首个垂直切片，由变更
  `archive/2026-10-29-adopt-polyglot-stack` 归档生成）
