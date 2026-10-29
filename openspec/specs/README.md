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

当前状态：尚未建立任何规约域（骨架阶段）。
第一个变更完成后，此目录会出现首个 `<capability>/spec.md`。
