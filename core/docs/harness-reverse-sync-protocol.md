# Harness 反向沉淀协议（Protocol）

本协议规定**何时**、**如何**、**由谁**把业务仓的经验反向同步到 `godot-ai-harness`，确保多个业务仓持续受益于彼此的踩坑与抽象。

## 1. 角色

- **业务仓 AI 助手（Cursor session）**：识别可沉淀经验、起草分类清单、生成 brief。
- **用户**：最终决定"通用 vs 专有"边界，确认 push 时机。
- **harness 仓**：被动接受来自任意业务仓的提炼，不主动产出。

## 2. 触发时机

### 强制触发（每次都要做）

- 任意 Phase 的 gate-check 通过后、关闭 Phase 之前。
- 解决 P0 / P1 级别的踩坑后（明显影响多项目的）。

### 推荐触发

- 完成跨系统重构后。
- 一周开发周期结束前（如有定期节奏）。
- 用户问"最近的经验有什么可以沉淀的"时。

### 禁止触发

- 玩法 / 数值 / 资源调整后。这些是项目专有，写到 `docs/ai_project_memory.md` 而非 harness。
- 临时调试代码或一次性脚本。
- 不确定通用性的内容（先观察 1~2 个 phase，确认重复出现再沉淀）。

## 3. 通用 vs 专有判定

### "通用"的硬性标准（同时满足）

- 换一个 Godot 4.x 项目仍然成立
- 不依赖任何项目专有的世界观/玩法/资源命名
- 至少在 2 个或以上业务仓有复现可能

### 默认归类（参考）

| 类型 | 通用归 | 专有归 |
|---|---|---|
| 引擎踩坑 | `core/memory/godot_pitfalls.md` | `docs/ai_project_memory.md` |
| 工程踩坑（git/shell/bootstrap） | `core/memory/harness_ops_pitfalls.md` | `docs/ai_project_memory.md` |
| Cursor / ClaudeCode 协作流程 | `core/rules/*.mdc` 或 `core/skills/` | 不放业务仓 |
| Godot 4 + GDScript 通用规范 | `core/rules/godot-4-gdscript-standards.mdc` | 项目专有命名规则放 `.cursor/rules/project-*.mdc` |
| 跨项目可复用的 skill / command | `core/skills/` / `core/commands/` | 仅本项目流程放 `.cursor/skills/` / `.cursor/commands/` |
| 玩法相关任何东西 | ❌ 不放 harness | `docs/`、`scripts/`、`resources/` |

## 4. 操作流程（标准）

```
Phase 收尾 / 大坑解决
    ↓
[1] 跑 generate-harness-sync-brief.command 生成初稿
    ↓
[2] 人工补 "AI 问答复盘" 与 "可提炼候选" 段
    ↓
[3] 与用户对齐分类（通用 vs 专有）
    ↓
[4] cd vendor/godot-ai-harness → 写入 → commit → push
    ↓
[5] 回业务仓 → git add vendor/godot-ai-harness → commit → push
    ↓
[6] 重跑 bootstrap（让本仓 .cursor/_harness_* 立刻拿到新内容）
    ↓
[7] 把 harness commit hash 与 业务仓 commit hash 回填到 brief 文件
```

## 5. 关键约束（违反必然踩坑）

- **必须先 push harness，再 push 业务仓**（详见 `harness_ops_pitfalls.md` H-002）。
- **不要在 harness 内做删除**（其他业务仓 `bootstrap --update` 后会失能）。
- **每次反向同步必须有 brief 文件留档**（`docs/harness-sync-briefs/<date>.md`）。
- **同步完成后必须重启 Cursor**（`.cursor/rules/` 不会热加载，详见 `harness_ops_pitfalls.md` H-201）。

## 6. 守门规则

- 任何业务仓的 push 都会触发 CI 检查 `.cursor/_harness_*` 与 `vendor/` 一致性。
- 如果 CI 失败，说明：要么有人手改了同步产物，要么忘了在 push 业务仓前先 push harness。
- 守门 workflow 模板：`vendor/godot-ai-harness/templates/ci/harness-sync-check.yml`

## 7. 度量（建议）

可以通过以下方式跟踪反向沉淀健康度：

- harness commit log 中"Promote X from Y"系列 commit 数量
- `docs/harness-sync-briefs/` 目录下文件数（每个文件代表一次执行）
- `core/memory/godot_pitfalls.md` 与 `harness_ops_pitfalls.md` 的条目增长曲线

## 8. 反例（明确不要做）

- ❌ 把"项目某张卡的伤害公式"沉淀到 harness
- ❌ 在 harness 内删除某条不再需要的规则（应该 deprecate 标注，不删除）
- ❌ 不写 brief 直接改 harness（其他人无法回溯"为什么改"）
- ❌ 一次反向同步包含 10+ 不相关主题（应拆成多次）
- ❌ 业务仓临时绕开 CI 的 `.cursor/_harness_*` 一致性检查
