# Godot AI Harness (Cursor + ClaudeCode)

AI harness for Godot (Cursor and ClaudeCode).

这是一个面向 Godot 项目的双客户端 AI 协作框架仓库，目标是：

- 在 Cursor 与 ClaudeCode 之间共享同一套通用流程。
- 将通用规则、通用技能、通用 Agent、通用记忆沉淀在独立仓库。
- 让多个业务项目通过 git submodule 接入，**只需运行一次 bootstrap 脚本**即可启用所有 AI 资产。

## 目录说明

- `core/rules/`：跨项目通用 Cursor/ClaudeCode 规则（`.mdc`）。
  - 包含 `_harness_active.mdc`：被加载即触发 AI 回复前缀【godot-ai-harness 生效中】。
- `core/skills/`：通用 skill（含 CCGS 提炼，74 个）。
- `core/agents/`：通用 agent 角色（含 CCGS 提炼，38 个）。
- `core/commands/`：通用命令模板。
- `core/hooks/`：通用 git/agent 钩子（来自 CCGS）。
- `core/docs/`：通用文档与 CCGS 参考资料（`core/docs/ccgs/`）。
- `core/memory/`：跨项目通用记忆。
- `adapters/cursor/`：Cursor MCP 与规则适配模板。
- `adapters/claudecode/`：ClaudeCode 适配模板。
- `templates/`：项目级本地配置模板。
- `scripts/`：客户端配置下发脚本。
  - `use-cursor.bat` / `use-cursor.command`：全量同步到业务仓 `.cursor/_harness_*`。
  - `use-claude.bat` / `use-claude.command`：全量同步到业务仓 `.claude/_harness_*`。

## 业务仓接入方式

在业务仓内添加 submodule：

```bash
git submodule add https://github.com/visionTw/godot-ai-harness.git vendor/godot-ai-harness
```

然后准备业务仓的 bootstrap 脚本（参考 `Game_Desktop/tools/harness/bootstrap.command`），它会：

1. `git submodule update --init --recursive vendor/godot-ai-harness`
2. 调用 `vendor/godot-ai-harness/scripts/use-cursor.{bat,command}`
3. 业务仓 `.cursor/` 下会出现 `_harness_*` 同步资产

新机器克隆业务仓后，**只需运行一次 `tools/harness/bootstrap.{command,bat}`** 即可完成所有 AI 配置。

## 启用感知

`.cursor/rules/_harness_active.mdc`（来自 `core/rules/`）一旦加载，AI 助手回复正文最开头会自动出现：

```
【godot-ai-harness 生效中】
```

这是判断 harness 是否成功生效最直接的信号。

## CCGS 资产说明

`core/` 下大量 skill / agent / hook / docs 内容来自 [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)，已按"对所有 Godot 项目可复用"标准筛选：

- 已纳入：通用 game design / qa / production / gameplay / gdscript / shader / godot 相关。
- 已剔除：unity-*、ue-*、unreal-* 与 godot-csharp/gdextension 专属内容。
- 文档原件保留在 `core/docs/ccgs/`（含 `CCGS_LICENSE`、`CCGS_README.md`、`CCGS_CLAUDE.md`、`UPGRADING.md`、原始 rules/templates/hooks-reference）。

## 约定

- 不在本仓库存放任何具体项目玩法、阶段日志与业务代码。
- 项目专有知识应留在业务仓库（例如 `docs/ai_project_memory.md`）。
- 修改 `core/` 后，业务仓需重跑 bootstrap 才能拿到更新；并需 `git add vendor/godot-ai-harness` 推进 submodule 指针。
