# apps/web（占位）

前端可部署单元。**技术栈待定**——选型必须走 openspec 变更。

## 启动一个选型变更

```bash
bash scripts/new-change.sh choose-web-stack "确定前端技术栈"
```

然后：

1. `design.md` 列 2-3 个候选，重点写**放弃了什么**
2. `docs/decisions/NNNN-*.md` 写 ADR（含适用条件与失效条件）
3. 候选对比维度至少包含：渲染模式、构建速度、包体积、SSR/静态导出、团队熟悉度
4. 定稿后更新 `harness/context/architecture.md` 的「当前状态」
5. 建 `apps/web/package.json`，补 `typecheck` / `test` / `build` 脚本，
   让 `scripts/verify.sh` 能真实覆盖到它

## 边界

- 不直接连数据库；数据经 `apps/api` 或服务端接口
- 只依赖 `packages/shared`（类型与纯函数）与本包内部模块
