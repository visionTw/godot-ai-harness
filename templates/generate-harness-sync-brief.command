#!/bin/zsh
# ============================================================================
# Generate Harness Sync Brief — 业务仓模板
# 用途：扫描最近 N 条业务仓 commit，生成"可提炼到 harness 的候选清单"初稿。
# 用法：./tools/harness/generate-harness-sync-brief.command [N]
#   N 默认 12
# 输出：docs/harness-sync-briefs/YYYY-MM-DD_HHMM.md
# 后续：手工补"AI 问答复盘"段后，执行 /sync-learnings-to-harness 走完整流程
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

COMMIT_COUNT="${1:-12}"
DATE_TAG="$(date '+%Y-%m-%d_%H%M')"
OUT_DIR="docs/harness-sync-briefs"
OUT_FILE="${OUT_DIR}/${DATE_TAG}.md"

mkdir -p "$OUT_DIR"

{
  echo "# Harness Sync Brief"
  echo
  echo "- 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "- 生成来源: \`tools/harness/generate-harness-sync-brief.command\`"
  echo "- 分析提交数: 最近 ${COMMIT_COUNT} 条"
  echo
  echo "## 最近提交"
  echo
  git log -n "$COMMIT_COUNT" --pretty=format:'- `%h` %s'
  echo
  echo
  echo "## 提交涉及文件（去重）"
  echo
  git log -n "$COMMIT_COUNT" --name-only --pretty=format: | awk 'NF' | sort -u | sed 's/^/- `/' | sed 's/$/`/'
  echo
  echo "## 可提炼到 Harness（候选）"
  echo
  echo "- 规则（rules / *.mdc）："
  echo "  - "
  echo "- 技能（skills / SKILL.md）："
  echo "  - "
  echo "- 命令（commands / *.md）："
  echo "  - "
  echo "- 通用记忆（memory / godot_pitfalls / harness_ops_pitfalls）："
  echo "  - "
  echo
  echo "## 留在项目仓库（专有）"
  echo
  echo "- 项目特有逻辑："
  echo "  - "
  echo "- 项目特有文档/配置："
  echo "  - "
  echo
  echo "## AI 问答复盘（手工补充）"
  echo
  echo "- 关键问题："
  echo "  - "
  echo "- 最终决策："
  echo "  - "
  echo "- 可复用经验："
  echo "  - "
  echo
  echo "## 同步执行记录"
  echo
  echo "- Harness 提交: "
  echo "- 业务仓提交: "
  echo "- 备注: "
} > "$OUT_FILE"

echo "Generated: $OUT_FILE"
echo
echo "下一步："
echo "  1. 打开 $OUT_FILE 手工补充"AI 问答复盘"与"可提炼候选""
echo "  2. 执行 /sync-learnings-to-harness 走完整反向沉淀流程"
