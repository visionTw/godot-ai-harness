# Onboarding

## 1. 接入新业务仓

### 1.1 添加 submodule

在业务仓根目录：

```bash
git submodule add https://github.com/visionTw/godot-ai-harness.git vendor/godot-ai-harness
git commit -m "Add godot-ai-harness submodule"
```

### 1.2 准备 bootstrap 脚本

参考 `Game_Desktop` 业务仓的实现，复制以下文件到新业务仓：

- `tools/harness/bootstrap.command`（macOS）
- `tools/harness/bootstrap.bat`（Windows）
- `tools/harness/project.harness.json`（修改 `projectSlug`）

## 2. 一键启用

在业务仓根目录：

- macOS：`./tools/harness/bootstrap.command`
- Windows：`tools\harness\bootstrap.bat`

可选 `--client cursor|claude|both`（默认 `cursor`）。

bootstrap 自动完成：

1. `git submodule update --init --recursive vendor/godot-ai-harness`
2. 同步 `core/rules/`、`core/skills/`、`core/commands/`、`core/agents/` 到业务仓 `.cursor/_harness_*`
3. 同步 `adapters/cursor/mcp.template.json` 到业务仓 `.cursor/mcp.json`

## 3. 验证启用

打开 Cursor，新建会话提问任意问题，AI 回复正文开头应出现：

```
【godot-ai-harness 生效中】
```

如果没出现：

- 检查 `.cursor/rules/_harness_active.mdc` 是否存在；
- 重跑 bootstrap；
- 在 Cursor 设置中确认 `.cursor/rules/` 被加载。

## 4. 项目分层原则

- 通用知识留在 harness 仓库（`core/`）。
- 项目专有知识留在业务仓库（`.cursor/rules/` 中无 `_harness_` 前缀的部分；`docs/ai_project_memory.md`）。
- `_harness_*` 同步产物视为只读，**禁止手工编辑**——重跑 bootstrap 会覆盖。

## 5. 升级 harness

```bash
cd vendor/godot-ai-harness
git pull origin main
cd ../..
./tools/harness/bootstrap.command   # 重新同步
git add vendor/godot-ai-harness     # 推进 submodule 指针
git commit -m "Bump godot-ai-harness to <hash>"
```

## 6. 推荐先用的通用能力

- 改动后闭环规则：`core/rules/post-change-runtime-check.mdc`
- 启用标识规则：`core/rules/_harness_active.mdc`
- 阶段执行规则：`core/rules/phase-execution-checklist.mdc`
- 会话接力规则：`core/rules/session-handoff-docs-workflow.mdc`
- 通用命令：`core/commands/post-change-runtime-check.md`、`windows-package-local.md`
- CCGS 协作工作流参考：`core/docs/ccgs/workflow-catalog.yaml`、`core/docs/ccgs/coordination-rules.md`
