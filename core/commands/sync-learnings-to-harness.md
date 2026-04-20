# /sync-learnings-to-harness

把业务仓最近学到的"可复用通用经验"反向沉淀到 `godot-ai-harness`，让其他业务仓也能受益。

## 触发时机（什么时候用这个命令）

- 每个 Phase 收尾时（建议作为 phase 关闭的最后一个动作）。
- 完成一次跨系统重构后。
- 解决了一个值得记录的非平凡踩坑后。
- 用户明确要求"这次的经验整理沉淀一下"时。

## 输入材料

- 最近 N 条 commit（默认 12 条；可配 `/generate-harness-sync-brief` 先生成清单）。
- 最近会话中关键的 AI 问答与决策。
- 阶段开发日志 `docs/phases/phase-*/development_log.md`。

## 提炼标准（什么算"通用"）

| 通用（沉淀到 harness） | 项目专有（留在业务仓） |
|---|---|
| Godot 引擎踩坑 → `core/memory/godot_pitfalls.md` | 玩法逻辑、卡牌/敌人数值、玩法专有 FSM |
| harness/git/shell 踩坑 → `core/memory/harness_ops_pitfalls.md` | 项目专有的工程脚本路径 |
| 通用 GDScript 规范 → `core/rules/godot-4-gdscript-standards.mdc` | 项目专有命名/资源约束（如 `project-roguecard.mdc`） |
| 跨项目复用的 skill / command 模板 → `core/skills/` / `core/commands/` | 仅在某个项目玩法范畴下的步骤 |
| 与 Godot/MCP/Cursor 工作流相关的通用流程 → `core/rules/godot-mcp-workflow.mdc` 等 | 项目专有 smoke/regression 路径 |

> **判断口诀**：换一个 Godot 4.x 项目还成立 → 通用；只有本项目世界观/玩法/资源结构成立 → 专有。

## 执行清单（推荐顺序）

1. **生成基础清单**：跑 `./tools/harness/generate-harness-sync-brief.command`（输出到 `docs/harness-sync-briefs/<date>.md`）。
2. **手工补"AI 问答复盘"段**：把会话中关键决策、踩坑、通用方法补进去。
3. **逐条分类**：每个候选项标记"通用 / 专有"，在"可提炼到 Harness"和"留在项目仓库"两段下分别填位置。
4. **harness 改动**：
   - `cd vendor/godot-ai-harness`
   - 按分类把内容写入对应位置（rules/skills/commands/memory/docs）
   - `git add ... && git commit -m "..."`
   - `git push origin main`
5. **业务仓推进 submodule 指针**：
   - `cd <business-repo>`
   - `git add vendor/godot-ai-harness`
   - `git commit -m "Bump godot-ai-harness to <hash>: <what>"`
   - `git push`
6. **重新跑 bootstrap**（可选，让本仓的 `.cursor/_harness_*` 立刻拿到新内容）：
   - `./tools/harness/bootstrap.command`
7. **填同步执行记录**：在 `docs/harness-sync-briefs/<date>.md` 末尾补 harness commit hash 与 业务仓 commit hash。

## 提交顺序硬性约束

- **必须先 push harness，再 push 业务仓**。
- 否则业务仓的 submodule 指针会指向远端不存在的 commit（CI 会失败，详见 `harness_ops_pitfalls.md` H-002）。

## 输出归档

每次执行后：

- `docs/harness-sync-briefs/<date>.md`：本次反向同步的完整清单与执行记录
- harness 仓的 commit log：通用经验沉淀痕迹
- 业务仓的 commit log："Bump godot-ai-harness" 提交，便于回溯

## 与 /generate-harness-sync-brief 的关系

`/generate-harness-sync-brief` 只是**起点**——自动生成"近期提交摘要 + 候选模板"。本命令是**完整流程**——从摘要到 push 完成的所有步骤。
