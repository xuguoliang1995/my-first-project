# 0003 采用 AIWorkSpace 多仓库工作区（api/web 拆为 git submodule）

- 状态：已采纳
- 日期：2026-10-29
- 关联变更：无（本次为仓库结构性变更，按用户"例外处理、直接执行"指令完成，**未走 openspec 变更**，违反 R-1，见「后果」）

## 背景

0002 落地后，`apps/api`（Spring Boot）与 `apps/web`（React + Vite）是父仓库
`my-first-project` **直接追踪的普通目录**，与 `harness/`、`openspec/`、`skills/`
同仓。用户要求把工作区升级为 **AIWorkSpace**：父仓库承载规约与执行框架，
两个应用作为独立 git 仓库、以 **submodule** 形式引入，并在 `AGENTS.md` 说明。

不决策会出的问题：

1. api/web 要成为可被其他项目/CI 独立引用的仓库，就必须有自己的 git 历史与远端；
   继续留在父仓库里，它们的提交与父仓库规约提交混在一条时间线上，无法独立发版。
2. 本机开发环境访问 github 不稳定（实测间歇性 `Failed to connect ... port 443`），
   若直接把 `.gitmodules` 指向 github 而 commit 尚未推上去，父仓库指针会指向
   github 上**不存在的 commit**，别人 clone 后 `submodule update` 直接坏掉。
3. 父仓库远端命名（`.../api`、`.../web`）与本地兄弟目录名（`my-first-project-api`、
   `my-first-project-web`）**不一致**——这决定了相对 URL 方案不可用（见「决策」）。

## 决策

**父仓库保留规约/harness/skills；`apps/api`、`apps/web` 拆为两个独立 git 仓库并
以 submodule 挂载。分两步收敛，避免制造坏引用：**

| 维度 | 当前（已落地，离线可验证） | 终态（github 可达后执行） |
| --- | --- | --- |
| 子仓库来源 | 用现有 `apps/*` 代码在 `../my-first-project-api`、`../my-first-project-web` `git init` + 首次提交 | 各自 `git push` 到 `https://github.com/xuguoliang1995/{api,web}` |
| `.gitmodules` url | **绝对本地路径**（`/Users/.../my-first-project-api`），本地 submodule 的 origin 亦指向该路径 | **绝对 github URL**（`https://github.com/xuguoliang1995/api`、`.../web`），随后 `git submodule sync` |
| 父仓库远端 | `origin = https://github.com/xuguoliang1995/my-first-project`（已配置，尚未 push） | push `main` |

**关键约束：不使用相对 URL（`../xxx`）。** 因为 git 在 clone/update 时会把
submodule 的相对 URL **按父仓库的 remote 解析**；父仓库在 github 上，`../my-first-project-api`
会被解析成 `github.com/xuguoliang1995/my-first-project-api`（不存在），
无法映射到实际的 `.../api`。因此两阶段都必须用**绝对 URL**。

## 理由

- **两阶段而非一步到位**：github 链路当前不可靠，且子仓库 commit 尚只在本地。
  先把结构在本地做扎实（可 `verify.sh` + 真实 `git clone --recurse-submodules` 验证），
  推送与切 URL 留到网络稳定时一条命令收敛，避免"父仓库指向空 github 仓库"的坏状态。
- **绝对本地路径作为过渡**：相对路径在本地也会因父仓库 origin 已是 github 而被
  `submodule sync` 解析成错误的 github URL；绝对本地路径不受父仓库 remote 影响，离线稳定。
- **规约仍集中在父仓库**：跨 api/web 的行为契约继续走父仓库 `openspec/`，
  避免"多仓=多套规约"的认知分裂。

## 放弃的方案

| 方案 | 放弃原因 |
| --- | --- |
| 保持单仓（不拆 submodule） | 与用户"升级为 AIWorkSpace、api/web 作 submodule"的明确诉求冲突 |
| `.gitmodules` 用相对 URL `../my-first-project-api` | 与 github 仓库命名（`api`/`web`）不匹配，父仓库在 github 时解析出错误 URL，clone 即坏 |
| 直接把 `.gitmodules` 指向 github 绝对 URL（跳过本地阶段） | github 当前不可达且 commit 未推送；会造出指向空/缺失仓库的坏引用，违反 R-3（无验证证据不声称完成） |
| 用 git subtree 替代 submodule | subtree 把子仓库历史并入父仓库单线，正是本次要消除的"无法独立发版"问题 |
| 现在就 `git push` 三个仓库 | 实测连续 connect timeout，非确定性能成功；不应在坏链路上留下半完成状态 |

## 后果

**正面：**

- api/web 成为各自有独立历史的仓库，可被其他工作区/CI 单独引用与发版
- 父仓库回归"规约 + 执行框架"定位，代码与契约提交解耦
- 全程离线即可验证结构正确（`verify.sh` 六阶段通过 + `clone --recurse-submodules` 可还原）

**负面（必须写）：**

- **违反 R-1**：本次结构变更未先建 openspec 变更（用户指令例外）。建议补一条
  `restructure-aiworkspace` 变更或在下次触碰架构时一并固化判据。
- **多了一层 submodule 心智负担**：首次克隆必须 `--recurse-submodules`；改子仓库内容
  必须"先在子仓库 commit/push，再在父仓库更新指针"，顺序错则指针悬空。
- **两阶段收尾依赖网络**：github 切换 + 三仓库推送尚未完成，工作区仍处"本地可跑、
  远端未就绪"的中间态。
- **命名不一致是长期坑**：本地目录 `my-first-project-api` 与远端 `api` 名字不同，
  切 URL 时必须手填绝对 github URL，不能靠 sync 自动推导。

## 适用条件

- 项目定位确为"一个规约父仓库 + 多个独立应用仓库"的 AIWorkSpace
- 团队成员/CI 能访问三个 github 仓库并完成首次推送后，终态绝对 URL 才成立
- 在 github 推送完成前，`.gitmodules` 保持绝对本地路径仅对本机有效，
  **不可跨机器 clone**（其他人拿不到 `/Users/.../my-first-project-api`）

## 失效条件

- 若 api/web 需要与父仓库严格原子发版、共享一条 CI 门禁 → 回退单仓（回到 0002 的 B2 形态）
- 若 github 仓库改名或与本地目录对齐（如都叫 `my-first-project-api`）→ 可改用相对 URL，简化多机协作
- 若引入超过两个独立应用仓库、submodule 管理成本上升 → 重新评估 monorepo 工具（如 nx/turborepo）或迁移到包管理器 workspace 方案
