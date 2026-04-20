@echo off
REM ============================================================================
REM Godot AI Harness 一键 bootstrap 脚本（Windows）— 业务仓模板
REM 使用方式：把本文件拷贝到业务仓 tools\harness\bootstrap.bat
REM 行为：
REM   1. 若 vendor\godot-ai-harness 不存在 → 自动 git submodule update --init
REM      若已存在 → 默认保留本地 HEAD（除非 --strict）
REM   2. 检测 harness 远端是否有新版本（self-update 检测）
REM   3. 同步 harness 通用 rules/skills/commands/agents 到 .cursor\_harness_*
REM   4. 启用回复前缀【godot-ai-harness 生效中】
REM 用法：在业务仓根目录运行：tools\harness\bootstrap.bat
REM 可选参数：
REM   --client cursor|claude|both   选择目标客户端（默认 cursor）
REM   --update                      允许自动 git pull 升级 vendor 到 origin/main
REM   --skip-update-check           跳过远端检测（离线环境）
REM   --strict                      强制把 vendor 对齐到业务仓 index 记录的指针
REM ============================================================================
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%..\..") do set PROJECT_ROOT=%%~fI
set HARNESS_PATH=vendor\godot-ai-harness
set CLIENT=cursor
set AUTO_UPDATE=0
set SKIP_UPDATE_CHECK=0
set STRICT=0

:parse_args
if "%~1"=="" goto after_args
if /I "%~1"=="--client" (
  set CLIENT=%~2
  shift
  shift
  goto parse_args
)
if /I "%~1"=="--update" (
  set AUTO_UPDATE=1
  shift
  goto parse_args
)
if /I "%~1"=="--skip-update-check" (
  set SKIP_UPDATE_CHECK=1
  shift
  goto parse_args
)
if /I "%~1"=="--strict" (
  set STRICT=1
  shift
  goto parse_args
)
shift
goto parse_args
:after_args

echo ============================================================
echo   Godot AI Harness Bootstrap
echo ============================================================
echo   PROJECT_ROOT = %PROJECT_ROOT%
echo   CLIENT       = %CLIENT%
echo   AUTO_UPDATE  = %AUTO_UPDATE%
echo   STRICT       = %STRICT%
echo ------------------------------------------------------------

cd /d "%PROJECT_ROOT%"

if not exist "project.godot" (
  echo [Warning] project.godot not found in PROJECT_ROOT.
  echo   This bootstrap is meant for a Godot business repo.
  echo   Continuing anyway...
)

where git >nul 2>&1
if errorlevel 1 (
  echo [Error] git is required but not installed.
  exit /b 1
)

if not exist ".gitmodules" (
  echo [Error] .gitmodules not found. Add the harness submodule first:
  echo   git submodule add https://github.com/visionTw/godot-ai-harness.git %HARNESS_PATH%
  exit /b 1
)

findstr /C:"%HARNESS_PATH%" .gitmodules >nul
if errorlevel 1 (
  echo [Error] %HARNESS_PATH% submodule not registered in .gitmodules.
  exit /b 1
)

echo [1/4] Ensuring submodule is initialized: %HARNESS_PATH%
set VENDOR_PRESENT=0
if exist "%HARNESS_PATH%\.git" set VENDOR_PRESENT=1

if "%VENDOR_PRESENT%"=="0" (
  echo   [Init] vendor missing, running submodule update --init --recursive...
  git submodule update --init --recursive %HARNESS_PATH%
  if errorlevel 1 (
    echo [Error] Failed to update submodule.
    exit /b 1
  )
) else (
  if "%STRICT%"=="1" (
    echo   [Strict] aligning vendor to business-repo index pointer...
    git submodule update --init --recursive %HARNESS_PATH%
  ) else (
    for /f "delims=" %%P in ('git ls-tree HEAD "%HARNESS_PATH%" 2^>nul') do (
      for /f "tokens=3" %%Q in ("%%P") do set IDX_PTR=%%Q
    )
    for /f "delims=" %%H in ('git -C "%HARNESS_PATH%" rev-parse HEAD 2^>nul') do set VENDOR_HEAD=%%H
    if not "!IDX_PTR!"=="!VENDOR_HEAD!" (
      echo   [Note] vendor HEAD differs from business-repo index:
      echo     index  : !IDX_PTR!
      echo     vendor : !VENDOR_HEAD!
      echo     Preserving vendor HEAD. Run with --strict to force-align.
      echo     Or commit the new pointer:  git add %HARNESS_PATH% ^&^& git commit
    ) else (
      echo   [OK] vendor already initialized.
    )
  )
)

if not exist "%HARNESS_PATH%\scripts" (
  echo [Error] %HARNESS_PATH%\scripts not found.
  exit /b 1
)

echo [2/4] Checking harness remote for updates...
if "%SKIP_UPDATE_CHECK%"=="1" (
  echo   [Skip] --skip-update-check set.
  goto after_update_check
)

for /f "delims=" %%H in ('git -C "%HARNESS_PATH%" rev-parse HEAD 2^>nul') do set HARNESS_OLD_HEAD=%%H
git -C "%HARNESS_PATH%" fetch --quiet origin main >nul 2>&1
if errorlevel 1 (
  echo   [Warn] Could not fetch from harness remote ^(offline?^). Continuing with local copy.
  goto after_update_check
)
for /f "delims=" %%H in ('git -C "%HARNESS_PATH%" rev-parse origin/main 2^>nul') do set HARNESS_REMOTE=%%H

if "%HARNESS_OLD_HEAD%"=="%HARNESS_REMOTE%" (
  echo   [OK] vendor is up to date with origin/main.
  goto after_update_check
)

echo   [Info] Local vendor:  %HARNESS_OLD_HEAD%
echo   [Info] Remote main:   %HARNESS_REMOTE%
echo   [Info] vendor is behind origin/main.
if "%AUTO_UPDATE%"=="1" (
  echo   [Update] --update set, pulling latest...
  git -C "%HARNESS_PATH%" checkout main 2>nul
  git -C "%HARNESS_PATH%" pull --ff-only origin main
  echo   [Update] Done. Don't forget to:
  echo     git add %HARNESS_PATH% ^&^& git commit -m "Bump godot-ai-harness" ^&^& git push
) else (
  echo   [Hint] Run with --update to auto-pull, or manually:
  echo     cd %HARNESS_PATH% ^&^& git checkout main ^&^& git pull origin main
  echo     cd %PROJECT_ROOT% ^&^& git add %HARNESS_PATH% ^&^& git commit ^&^& git push
)

:after_update_check

if /I "%CLIENT%"=="cursor" goto apply_cursor
if /I "%CLIENT%"=="claude" goto apply_claude
if /I "%CLIENT%"=="both" goto apply_both
echo [Error] Unknown --client value: %CLIENT% (expected cursor^|claude^|both)
exit /b 1

:apply_cursor
echo [3/4] Applying Cursor configuration...
call "%HARNESS_PATH%\scripts\use-cursor.bat" --project-root "%PROJECT_ROOT%"
goto verify

:apply_claude
echo [3/4] Applying ClaudeCode configuration...
call "%HARNESS_PATH%\scripts\use-claude.bat" --project-root "%PROJECT_ROOT%"
goto verify

:apply_both
echo [3/4] Applying Cursor configuration...
call "%HARNESS_PATH%\scripts\use-cursor.bat" --project-root "%PROJECT_ROOT%"
echo [3/4] Applying ClaudeCode configuration...
call "%HARNESS_PATH%\scripts\use-claude.bat" --project-root "%PROJECT_ROOT%"
goto verify

:verify
echo [4/4] Verifying activation...
if exist "%PROJECT_ROOT%\.cursor\rules\_harness_active.mdc" (
  echo   [OK] _harness_active marker installed.
) else (
  if exist "%PROJECT_ROOT%\.claude\rules\_harness__harness_active.md" (
    echo   [OK] _harness_active marker installed.
  ) else (
    echo   [Warn] _harness_active marker not found. Check harness version.
  )
)

echo.
echo ============================================================
echo   [OK] Godot AI Harness Activated
echo ============================================================
echo   Next steps:
echo     - Reopen Cursor, ensure godot MCP server is loaded
echo     - In new chats, AI replies should begin with [godot-ai-harness on]
echo     - Update harness: tools\harness\bootstrap.bat --update
echo     - First clone alignment: tools\harness\bootstrap.bat --strict
echo.

endlocal
