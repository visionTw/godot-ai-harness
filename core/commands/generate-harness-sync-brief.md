# /generate-harness-sync-brief

快速生成"近期提交可提炼到 harness 的候选清单"，作为 `/sync-learnings-to-harness` 的起点。

## 何时执行

- 在打算做 `/sync-learnings-to-harness` 之前。
- 阶段中期想看看"最近哪些工作有反向沉淀价值"时。
- 用户问"最近有什么可以沉淀到 harness 的"时。

## 执行命令

```bash
./tools/harness/generate-harness-sync-brief.command
```

可选：指定分析最近提交数（默认 12）

```bash
./tools/harness/generate-harness-sync-brief.command 20
```

## 输出位置

- `docs/harness-sync-briefs/YYYY-MM-DD_HHMM.md`

## 输出包含

1. 最近 N 条 commit 列表（hash + subject）
2. 这些 commit 涉及的所有文件（去重）
3. 三段空白分类模板（rules / skills / commands）等待人工填写
4. "AI 问答复盘"模板段落
5. "同步执行记录"模板（最终回填 harness commit + game commit）

## 后续动作

1. 打开生成的 brief 文件，**人工补充**：
   - "可提炼到 Harness（候选）"段：哪些通用经验值得提炼
   - "留在项目仓库（专有）"段：哪些必须留在业务仓
   - "AI 问答复盘"段：会话中的关键决策与踩坑
2. 执行 `/sync-learnings-to-harness` 完成实际沉淀

## 前置脚本

业务仓需要存在 `tools/harness/generate-harness-sync-brief.command`。
新业务仓可以从 harness 模板拷贝：

```bash
cp vendor/godot-ai-harness/templates/generate-harness-sync-brief.command tools/harness/
chmod +x tools/harness/generate-harness-sync-brief.command
```
