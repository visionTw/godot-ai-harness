#!/bin/zsh
# ============================================================================
# Godot AI Harness 一键 bootstrap 脚本（macOS）— 业务仓模板
# 使用方式：把本文件拷贝到业务仓 tools/harness/bootstrap.command 并 chmod +x
# 行为：
#   1. 若 vendor/godot-ai-harness 不存在 → 自动 git submodule update --init
#      若已存在 → 默认保留本地 HEAD（除非 --strict）
#   2. 检测 harness 远端是否有新版本（self-update 检测）
#   3. 同步 harness 通用 rules/skills/commands/agents 到 .cursor/_harness_*
#   4. 启用回复前缀【godot-ai-harness 生效中】
# 用法：在业务仓根目录双击或 ./tools/harness/bootstrap.command
# 可选参数：
#   --client cursor|claude|both   选择目标客户端（默认 cursor）
#   --update                      允许自动 git pull 升级 vendor 到 origin/main
#   --skip-update-check           跳过远端检测（离线环境）
#   --strict                      强制把 vendor 对齐到业务仓 index 记录的指针
#                                 （首次 clone 业务仓后建议用一次；日常不需要）
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HARNESS_PATH="vendor/godot-ai-harness"
CLIENT="cursor"
AUTO_UPDATE=0
SKIP_UPDATE_CHECK=0
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --client)            CLIENT="$2"; shift 2 ;;
    --update)            AUTO_UPDATE=1; shift ;;
    --skip-update-check) SKIP_UPDATE_CHECK=1; shift ;;
    --strict)            STRICT=1; shift ;;
    *)                   shift ;;
  esac
done

cd "$PROJECT_ROOT"

echo "============================================================"
echo "  Godot AI Harness Bootstrap"
echo "============================================================"
echo "  PROJECT_ROOT = $PROJECT_ROOT"
echo "  CLIENT       = $CLIENT"
echo "  AUTO_UPDATE  = $AUTO_UPDATE"
echo "  STRICT       = $STRICT"
echo "------------------------------------------------------------"

if [ ! -f "project.godot" ]; then
  echo "[Warning] project.godot not found in PROJECT_ROOT."
  echo "  This bootstrap is meant for a Godot business repo."
  echo "  Continuing anyway..."
fi

if ! command -v git >/dev/null 2>&1; then
  echo "[Error] git is required but not installed."
  exit 1
fi

if [ ! -f ".gitmodules" ] || ! grep -q "$HARNESS_PATH" .gitmodules 2>/dev/null; then
  echo "[Error] $HARNESS_PATH submodule not registered in .gitmodules."
  echo "  Add it once with:"
  echo "    git submodule add https://github.com/visionTw/godot-ai-harness.git $HARNESS_PATH"
  exit 1
fi

echo "[1/4] Ensuring submodule is initialized: $HARNESS_PATH"
VENDOR_PRESENT=0
if [ -e "$HARNESS_PATH/.git" ]; then VENDOR_PRESENT=1; fi

if [ "$VENDOR_PRESENT" -eq 0 ]; then
  echo "  [Init] vendor missing, running submodule update --init --recursive..."
  git submodule update --init --recursive "$HARNESS_PATH"
elif [ "$STRICT" -eq 1 ]; then
  echo "  [Strict] aligning vendor to business-repo index pointer..."
  git submodule update --init --recursive "$HARNESS_PATH"
else
  IDX_PTR="$(git ls-tree HEAD "$HARNESS_PATH" 2>/dev/null | awk '{print $3}' || echo "")"
  VENDOR_HEAD="$(git -C "$HARNESS_PATH" rev-parse HEAD 2>/dev/null || echo "")"
  if [ -n "$IDX_PTR" ] && [ -n "$VENDOR_HEAD" ] && [ "$IDX_PTR" != "$VENDOR_HEAD" ]; then
    echo "  [Note] vendor HEAD differs from business-repo index:"
    echo "    index  : ${IDX_PTR:0:12}"
    echo "    vendor : ${VENDOR_HEAD:0:12}"
    echo "    Preserving vendor HEAD. Run with --strict to force-align."
    echo "    Or commit the new pointer:  git add $HARNESS_PATH && git commit"
  else
    echo "  [OK] vendor already initialized."
  fi
fi

if [ ! -d "$HARNESS_PATH/scripts" ]; then
  echo "[Error] $HARNESS_PATH/scripts not found."
  exit 1
fi

echo "[2/4] Checking harness remote for updates..."
if [ "$SKIP_UPDATE_CHECK" -eq 1 ]; then
  echo "  [Skip] --skip-update-check set."
else
  HARNESS_OLD_HEAD="$(git -C "$HARNESS_PATH" rev-parse HEAD 2>/dev/null || echo unknown)"
  if git -C "$HARNESS_PATH" fetch --quiet origin main 2>/dev/null; then
    HARNESS_REMOTE="$(git -C "$HARNESS_PATH" rev-parse origin/main 2>/dev/null || echo unknown)"
    if [ "$HARNESS_OLD_HEAD" != "$HARNESS_REMOTE" ] && [ "$HARNESS_REMOTE" != "unknown" ]; then
      BEHIND_COUNT="$(git -C "$HARNESS_PATH" rev-list --count "$HARNESS_OLD_HEAD..origin/main" 2>/dev/null || echo "?")"
      echo "  [Info] Local vendor:   ${HARNESS_OLD_HEAD:0:12}"
      echo "  [Info] Remote main:    ${HARNESS_REMOTE:0:12}"
      echo "  [Info] Behind by $BEHIND_COUNT commit(s)."
      if [ "$AUTO_UPDATE" -eq 1 ]; then
        echo "  [Update] --update set, pulling latest..."
        git -C "$HARNESS_PATH" checkout main 2>/dev/null || true
        git -C "$HARNESS_PATH" pull --ff-only origin main
        echo "  [Update] Done. Don't forget to:"
        echo "    git add $HARNESS_PATH && git commit -m \"Bump godot-ai-harness\" && git push"
      else
        echo "  [Hint] Run with --update to auto-pull, or manually:"
        echo "    cd $HARNESS_PATH && git checkout main && git pull origin main"
        echo "    cd $PROJECT_ROOT && git add $HARNESS_PATH && git commit && git push"
      fi
    else
      echo "  [OK] vendor is up to date with origin/main."
    fi
  else
    echo "  [Warn] Could not fetch from harness remote (offline?). Continuing with local copy."
  fi
fi

apply_cursor() {
  local script="$HARNESS_PATH/scripts/use-cursor.command"
  if [ ! -x "$script" ]; then chmod +x "$script" 2>/dev/null || true; fi
  echo "[3/4] Applying Cursor configuration..."
  "$script" --project-root "$PROJECT_ROOT"
}

apply_claude() {
  local script="$HARNESS_PATH/scripts/use-claude.command"
  if [ ! -x "$script" ]; then chmod +x "$script" 2>/dev/null || true; fi
  echo "[3/4] Applying ClaudeCode configuration..."
  "$script" --project-root "$PROJECT_ROOT"
}

case "$CLIENT" in
  cursor) apply_cursor ;;
  claude) apply_claude ;;
  both)   apply_cursor ; apply_claude ;;
  *)
    echo "[Error] Unknown --client value: $CLIENT (expected cursor|claude|both)"
    exit 1
    ;;
esac

echo "[4/4] Verifying activation..."
if [ -f "$PROJECT_ROOT/.cursor/rules/_harness_active.mdc" ] || \
   [ -f "$PROJECT_ROOT/.claude/rules/_harness__harness_active.md" ] || \
   [ -f "$PROJECT_ROOT/.claude/rules/_harness_active.md" ]; then
  echo "  [OK] _harness_active marker installed."
else
  echo "  [Warn] _harness_active marker not found. Check harness version."
fi

echo
echo "============================================================"
echo "  ✅ Godot AI Harness 已启用"
echo "============================================================"
echo "  下一步："
echo "    - 重新打开 Cursor，确认 MCP 面板中 godot server 已加载"
echo "    - 新会话中 AI 回复开头应出现【godot-ai-harness 生效中】"
echo "    - 升级 harness：./tools/harness/bootstrap.command --update"
echo "    - 首次 clone 后强制对齐：./tools/harness/bootstrap.command --strict"
echo
