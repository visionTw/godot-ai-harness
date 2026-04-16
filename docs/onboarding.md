# Onboarding

## 1. 初始化

1. Clone 本仓库到本地固定路径。
2. 准备项目私有配置：
   - 复制 `templates/project.local.template.json` 为本地文件。
3. 在目标业务项目根目录执行脚本：
   - Cursor: `scripts\\use-cursor.bat`
   - ClaudeCode: `scripts\\use-claude.bat`

## 2. 项目分层原则

- 通用知识留在 Harness 仓库。
- 项目专有知识留在业务项目仓库。
- 本地临时记忆建议放在未入库目录。

## 3. 推荐先用的通用能力

- 改动后闭环规则：`core/rules/post-change-runtime-check.mdc`
- 迭代收敛技能：`core/skills/iteration-close-loop/SKILL.md`
- 通用命令：
  - `core/commands/post-change-runtime-check.md`
  - `core/commands/windows-package-local.md`
