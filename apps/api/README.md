# apps/api（占位）

后端可部署单元。**技术栈待定**——选型必须走 openspec 变更。

## 启动一个选型变更

```bash
bash scripts/new-change.sh choose-api-stack "确定后端技术栈"
```

然后：

1. `design.md` 列 2-3 个候选（框架 + 运行时 + 数据库访问方式）
2. `docs/decisions/NNNN-*.md` 写 ADR
3. 候选对比维度至少包含：吞吐与延迟、类型安全、生态成熟度、部署形态、迁移成本
4. 定稿后更新 `harness/context/architecture.md` 的「当前状态」
5. 建 `apps/api/package.json`，补 `typecheck` / `test` / `build` 脚本

## 边界

- 不包含 UI 逻辑
- 鉴权与权限模型属于**全量规格**：必须写 `design.md` + ADR
  （见 `harness/rules/30-security-and-git.md` 第 8 条）
- 共享契约放 `packages/shared`，不在本包重复定义领域类型
