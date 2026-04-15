# Godot AI Harness (Cursor + ClaudeCode)

AI harness for Godot (Cursor and ClaudeCode).

这是一个面向 Godot 项目的双客户端 AI 协作框架仓库，目标是：

- 在 Cursor 与 ClaudeCode 之间共享同一套通用流程。
- 将通用规则、通用技能、通用 Agent、通用记忆沉淀在独立仓库。
- 允许业务项目仅维护项目专有知识与项目专有配置。

## 目录说明

- `core/`：跨项目通用资产（rules/skills/agents/memory）。
- `adapters/cursor/`：Cursor 适配模板与规则。
- `adapters/claudecode/`：ClaudeCode 适配模板。
- `templates/`：项目级本地配置模板。
- `scripts/`：一键切换脚本与配置下发脚本。
- `docs/`：接入说明、版本升级说明。

## 使用方式（简版）

1. 在业务项目中配置 `HARNESS_ROOT` 指向本仓库路径。
2. 复制 `templates/project.local.template.json` 为项目私有配置并填值。
3. 在业务项目运行：
   - `use-cursor.bat`（生成 Cursor 侧落地文件）
   - 或 `use-claude.bat`（生成 ClaudeCode 侧落地文件）

## 约定

- 不在本仓库存放任何具体项目玩法、阶段日志与业务代码。
- 项目专有知识应留在业务仓库（例如 `docs/ai_project_memory.md`）。
