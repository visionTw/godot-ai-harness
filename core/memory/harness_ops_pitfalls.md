## Harness 操作踩坑记录（跨项目共享）

本文件用于沉淀**所有使用 godot-ai-harness 的项目**在「harness 本身、bootstrap、git submodule、shell 客户端」操作过程中遇到的踩坑。

与 `godot_pitfalls.md` 区别：

- `godot_pitfalls.md`：Godot 引擎/GDScript 运行期踩坑。
- `harness_ops_pitfalls.md`：harness 维护、双仓库流转、AI 客户端配置过程中的踩坑（本文件）。

写入约定与 `godot_pitfalls.md` 一致：四段式（现象 / 根因 / 解决 / 影响范围），录入时间 + 发现项目，重复 +1。

---

## 一、Submodule 与 vendor 同步

### H-001 bootstrap 后 vendor HEAD 被回退到 index 旧 commit
- 现象：在业务仓内手动 `cd vendor/godot-ai-harness && git pull origin main` 把 vendor 推进到了新 commit，紧接着跑 `./tools/harness/bootstrap.command`，发现 vendor HEAD 又退回业务仓 index 里记录的旧 commit。
- 根因：bootstrap 第一步 `git submodule update --init --recursive vendor/godot-ai-harness` 的语义是"把 vendor 工作树对齐到业务仓 index 中记录的 submodule 指针"。即使 vendor 比 index 新，也会被强制 checkout 回 index 那个 commit。
- 解决：
  - 短期：升级 vendor 的正确顺序是 `pull → git add vendor/godot-ai-harness → git commit → git push → 然后再跑 bootstrap`。bootstrap 看到 index 已经是新值，submodule update 就是 no-op。
  - 长期：bootstrap 默认不再强制 reset vendor，仅在缺失时 `--init`；加 `--strict` 开关用于"强制对齐 index"的场景（如团队成员第一次 clone）。
- 影响范围：所有使用 git submodule 接入 harness 的业务仓。
- 录入：2026-04 / Game_Desktop。
- 复现频次：+2（bump_vendor_to_origin 第一版与第二版各栽一次）。

### H-002 跨仓库 commit ptr 后忘记 push 导致新成员 clone 失败
- 现象：本地把 harness 推进到了新 commit，业务仓的 submodule 指针也已 commit，但 harness 仓忘记 push 到 GitHub。新机器 clone 业务仓后跑 bootstrap，`git submodule update --init` 试图 fetch index 中那个新 commit，但远端没有，报 `fatal: needed object ... not found`。
- 根因：业务仓的 submodule 指针指向 harness 上一个**本地存在但远端没有**的 commit。
- 解决：双仓库改动**必须先 push harness，再 push 业务仓**。可在业务仓加 pre-push hook 检测当前 vendor HEAD 是否能在 origin/main 找到。
- 影响范围：所有 submodule 接入方式。
- 录入：2026-04 / Game_Desktop。

### H-003 `git submodule add file://...` 在新版 git 中被默认禁止
- 现象：开发期模拟"新仓接入 harness"时，用 `git submodule add file:///path/to/local/harness vendor/godot-ai-harness` 报 `fatal: transport 'file' not allowed`。
- 根因：git 2.38+ 出于 CVE-2022-39253 安全考虑默认禁用 `file://` 协议。
- 解决：临时绕过 `git -c protocol.file.allow=always submodule add ...`，或者直接用绝对路径（不带 `file://` 前缀，git 会按本地路径处理）。
- 影响范围：所有需要在本地模拟 submodule clone 的场景。
- 录入：2026-04 / Game_Desktop。

---

## 二、Shell 兼容性

### H-101 macOS zsh 下 `compgen -G` 找不到命令导致同步静默失败
- 现象：harness 的 `scripts/use-cursor.command` 用 `compgen -G "$DIR/*.mdc"` 检测是否有匹配文件。在 zsh 下（macOS 默认）`compgen` 不存在，rules/commands/agents 同步段全部跳过，但脚本 exit 0，看似成功实则 .cursor/_harness_* 没生成。
- 根因：`compgen` 是 bash 专属的内置命令，zsh 不实现。脚本 shebang 是 `#!/bin/zsh` 但内部用了 bash 语法。
- 解决：改用 zsh-friendly 的 `setopt NULL_GLOB` + 直接 `for f in "$DIR/"*.mdc; do [ -f "$f" ] || continue; ...; done`。
- 影响范围：所有 macOS 用户跑 harness 的 `.command` 脚本。已修复在 harness commit `f571d5a`。
- 录入：2026-04 / Game_Desktop。

### H-102 zsh 把 `#!/usr/bin/env bash` 当历史展开
- 现象：把多行 bash 脚本（开头是 `#!/usr/bin/env bash`）整段粘贴到 zsh 交互式终端，立刻报 `zsh: event not found: /usr/bin/env`。
- 根因：zsh 默认开启了历史展开（`!` 触发），shebang 行的 `!/usr/bin/env` 被当成历史命令引用。
- 解决：
  - 推荐：把脚本写成文件后用 `bash /path/to/script.sh` 执行，避免交互式 zsh 解析。
  - 备选：粘贴前 `setopt nobanghist` 或者把 `!` 转义为 `\!`。
- 影响范围：所有给用户"复制粘贴大段脚本"的场景。
- 录入：2026-04 / Game_Desktop。

### H-103 同步产物 `.cursor/_harness_*` 入 git 后体积膨胀
- 现象：选择"路线 B：同步产物入 git"后，Game_Desktop 的 `.cursor/skills/_harness_*/` 包含 74 个目录、数百个文件，commit 体积明显增大。
- 根因：CCGS 全量提炼后 skills 数量多；每次 harness 升级如果 skill 内容变化，所有业务仓都要带这些差异 commit。
- 解决：
  - 短期：接受体积代价，换"clone 后即可用"的体验。
  - 长期备选：改成"路线 A（同步产物 gitignore，bootstrap 时本地生成）"或加 sparse-checkout，仅同步项目用到的子集。
- 影响范围：所有走"路线 B"的业务仓。
- 录入：2026-04 / Game_Desktop。

---

## 三、AI 客户端配置

### H-201 Cursor 不会重新加载 .cursor/rules/ 直到重启会话
- 现象：bootstrap 把新规则同步到 `.cursor/rules/_harness_active.mdc`，但当前会话 AI 回复并未出现【godot-ai-harness 生效中】前缀。
- 根因：Cursor 的 `.cursor/rules/` 是会话启动时一次性加载，运行中新增/修改规则不会热更。
- 解决：bootstrap 跑完后必须**重启 Cursor 应用 / 关闭当前 chat 开新会话**，新规则才会生效。
- 影响范围：所有 alwaysApply 规则首次安装或更新场景。
- 录入：2026-04 / Game_Desktop。

---

## 四、Git / GitHub 操作

### H-301 团队 push 凭证统一 HTTPS 时，新仓 SSH remote 报 Host key verification failed
- 现象：在已经习惯 HTTPS push 的机器上，给新仓配 `git@github.com:...` SSH 形式 remote，push 报 `Host key verification failed`。
- 根因：用户从未通过 SSH 连过 github.com，`~/.ssh/known_hosts` 里没有 github.com 的 host key；且没配 SSH key 或 ssh-agent。
- 解决：
  - 简单做法：所有仓库统一用 HTTPS remote（`https://github.com/owner/repo.git`），共享同一份凭证（macOS Keychain / Git Credential Manager）。
  - 想用 SSH：至少需要 `ssh-keyscan github.com >> ~/.ssh/known_hosts` 添加 host key + 配置 SSH key 上传到 GitHub。
- 影响范围：AI 帮人配置新仓 remote 时；多机协作时凭证流不一致的场景。
- 录入：2026-04 / Game_RogueCard。

### H-302 GitHub 创建 repo 时勾 "Initialize with README" 导致首次 push 被拒
- 现象：本地仓库已有完整 README 与多个 commit，第一次 `git push -u origin main` 报 `! [rejected] main -> main (fetch first)`。
- 根因：GitHub Web UI 创建 repo 时勾选 "Initialize this repository with a README" 会在远端预先创建一个 `Initial commit`，与本地历史无共同祖先 → push 被拒。
- 解决：
  - 推荐：`git pull --rebase origin main`，把本地 commits 接到远端 Initial commit 之后；如果 README 冲突，`git checkout --ours README.md && git add README.md && git rebase --continue`（保留本地完整 README）。
  - 替代：`git push --force origin main`（仅在远端只有无意义的初始 README、且 100% 确认无人在用时使用）。
  - **预防**：在 GitHub 创建 repo 时**不要勾** "Initialize with README" / "Add .gitignore" / "Choose a license"，让远端为空仓库。
- 影响范围：所有"先本地写好再创建 GitHub repo"的工作流。
- 录入：2026-04 / Game_RogueCard。

### H-303 非交互终端 `git rebase --continue` 卡在 EDITOR
- 现象：在脚本 / AI agent / CI 等非交互场景跑 `git rebase --continue`，报 `error: Terminal is dumb, but EDITOR unset`，rebase 被中断。
- 根因：rebase 默认要打开 commit message 编辑器（即使是 cherry-pick / replay 类操作），无 EDITOR 就 fail。
- 解决：
  - `GIT_EDITOR=true git rebase --continue`（用 `true` 命令做 no-op editor）。
  - 或全局 `git config --global core.editor "true"`（仅在 AI / 脚本环境，不要对人工开发机这样配）。
  - 或 `git -c core.editor=true rebase --continue` 单次。
- 影响范围：AI agent / CI / cron 中所有用到 rebase / merge / commit 的场景。
- 录入：2026-04 / Game_RogueCard。

---

## 模板（复制使用）

```
### H-NNN 简短标题
- 现象：
- 根因：
- 解决：
- 影响范围：
- 录入：YYYY-MM / 项目名
- 复现频次：+1
```
