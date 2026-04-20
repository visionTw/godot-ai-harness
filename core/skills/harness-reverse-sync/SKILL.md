---
name: harness-reverse-sync
description: "Reverse-sync workflow that promotes business-repo learnings (rules, skills, commands, pitfalls) into godot-ai-harness so other repos benefit. Run at phase close, after major refactors, or after non-trivial debugging sessions."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Harness Reverse Sync Skill

把业务仓最近沉淀的"通用经验"反向同步到 `godot-ai-harness`。

## 何时触发

- **强烈推荐**：每个 Phase 收尾门禁检查的最后一步。
- 完成一次跨系统重构 / 非平凡踩坑后。
- 用户明确要求"整理一下最近的经验沉淀"。

## 输入

- 最近 N 条 commit（默认 12）。
- 最近会话的关键决策与踩坑（人工补充）。
- 阶段开发日志 `docs/phases/phase-*/development_log.md`。

## 步骤

### Step 1: 生成基础清单

```bash
./tools/harness/generate-harness-sync-brief.command [N]
```

输出：`docs/harness-sync-briefs/<date>.md`，已带最近 commit、涉及文件清单与空白模板。

### Step 2: 通用 vs 专有分类

打开生成的 brief 文件，按下表逐条分类：

| 内容类型 | 通用（写入 harness） | 专有（留业务仓） |
|---|---|---|
| Godot 引擎踩坑 | `vendor/godot-ai-harness/core/memory/godot_pitfalls.md` | `docs/ai_project_memory.md` |
| harness/git/shell 踩坑 | `vendor/godot-ai-harness/core/memory/harness_ops_pitfalls.md` | `docs/ai_project_memory.md` |
| GDScript / Godot 4 通用规范 | `vendor/godot-ai-harness/core/rules/*.mdc` | `.cursor/rules/project-*.mdc` |
| 工作流与流程模板（smoke / gate / phase） | `vendor/godot-ai-harness/core/rules/*.mdc` 或 `core/skills/` | `.cursor/rules/post-change-runtime-check.mdc`（项目专有版） |
| 跨项目复用的命令模板 | `vendor/godot-ai-harness/core/commands/*.md` | `.cursor/commands/`（无 `_harness_` 前缀） |

**判断口诀**：换一个 Godot 4.x 项目还成立 → 通用；只有本项目世界观/玩法/资源结构成立 → 专有。

### Step 3: 写入 harness

```bash
cd vendor/godot-ai-harness
# 把分类后的内容写入对应文件
git add <changed-files>
git commit -m "Promote <topic> from <project_slug>"
git push origin main
```

### Step 4: 业务仓推进 submodule 指针

```bash
cd <business-repo-root>
git add vendor/godot-ai-harness
git commit -m "Bump godot-ai-harness to <hash>: <what>"
git push
```

### Step 5: 重新跑 bootstrap 让本仓立刻拿到

```bash
./tools/harness/bootstrap.command
```

### Step 6: 回填同步执行记录

在 `docs/harness-sync-briefs/<date>.md` 末尾补：

- Harness 提交：`<hash>`
- 业务仓提交：`<hash>`
- 备注：本次提炼的核心总结

## 关键约束

1. **必须先 push harness，再 push 业务仓**（否则 CI 会失败，详见 `harness_ops_pitfalls.md` H-002）。
2. **不要把项目专有内容（玩法/数值/世界观）写入 harness**，会污染共享层。
3. **harness 的内容只能"加"和"改善"，不能"删除"** — 否则其他业务仓会丢能力。
4. **每次反向同步必须有 brief 文件留档**，便于回溯"什么时候因为什么把什么东西沉淀进去了"。

## 与 /generate-harness-sync-brief / /sync-learnings-to-harness 的关系

- `/generate-harness-sync-brief`：生成清单初稿（自动）
- 本 skill：完整流程的方法论（人 + AI 协作执行）
- `/sync-learnings-to-harness`：用户视角的命令入口，内部就是调用本 skill

## 频次建议

| 项目阶段 | 反向同步频次 |
|---|---|
| 项目早期（Phase 0~1） | 每 phase 一次 |
| 玩法稳定期（Phase 2~5） | 每 2~3 个 phase 一次，或遇到大坑后立即一次 |
| 后期内容期 | 仅在通用经验出现时按需触发 |

## 反例（不要这么做）

- ❌ 把"卡牌平衡数值表"写入 harness
- ❌ 把"乐队主题英雄技能列表"写入 harness
- ❌ 在 harness 内做任何破坏性修改（删除规则、删除 skill）
- ❌ 业务仓改完 harness 但忘了 commit `vendor/godot-ai-harness` 指针
- ❌ 同时改两个仓库但不 push harness 先 push 业务仓
