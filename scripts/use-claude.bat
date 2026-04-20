@echo off
setlocal enabledelayedexpansion

set HARNESS_ROOT=%~dp0..
set PROJECT_ROOT=%CD%

if "%~1"=="--project-root" (
  set PROJECT_ROOT=%~2
)

echo [Harness] Applying ClaudeCode configuration...
echo   HARNESS_ROOT = %HARNESS_ROOT%
echo   PROJECT_ROOT = %PROJECT_ROOT%

if not exist "%PROJECT_ROOT%" (
  echo [Error] PROJECT_ROOT not found: %PROJECT_ROOT%
  exit /b 1
)

if not exist "%PROJECT_ROOT%\.claude" mkdir "%PROJECT_ROOT%\.claude"
if not exist "%PROJECT_ROOT%\.claude\agents" mkdir "%PROJECT_ROOT%\.claude\agents"
if not exist "%PROJECT_ROOT%\.claude\skills" mkdir "%PROJECT_ROOT%\.claude\skills"
if not exist "%PROJECT_ROOT%\.claude\commands" mkdir "%PROJECT_ROOT%\.claude\commands"
if not exist "%PROJECT_ROOT%\.claude\rules" mkdir "%PROJECT_ROOT%\.claude\rules"

echo [Harness] Cleaning previous harness artifacts (_harness_*) ...
for %%F in ("%PROJECT_ROOT%\.claude\rules\_harness_*.md") do del /Q "%%F" 2>nul
for %%F in ("%PROJECT_ROOT%\.claude\commands\_harness_*.md") do del /Q "%%F" 2>nul
for %%F in ("%PROJECT_ROOT%\.claude\agents\_harness_*.md") do del /Q "%%F" 2>nul
for /D %%D in ("%PROJECT_ROOT%\.claude\skills\_harness_*") do rmdir /S /Q "%%D" 2>nul

echo [Harness] Syncing CLAUDE.md and mcp.json ...
copy /Y "%HARNESS_ROOT%\adapters\claudecode\CLAUDE.template.md" "%PROJECT_ROOT%\.claude\CLAUDE.md" >nul
copy /Y "%HARNESS_ROOT%\adapters\claudecode\mcp.template.json" "%PROJECT_ROOT%\.claude\mcp.json" >nul

echo [Harness] Syncing rules ...
for %%F in ("%HARNESS_ROOT%\core\rules\*.mdc") do (
  copy /Y "%%F" "%PROJECT_ROOT%\.claude\rules\_harness_%%~nF.md" >nul
)

echo [Harness] Syncing commands ...
for %%F in ("%HARNESS_ROOT%\core\commands\*.md") do (
  copy /Y "%%F" "%PROJECT_ROOT%\.claude\commands\_harness_%%~nxF" >nul
)

echo [Harness] Syncing agents ...
for %%F in ("%HARNESS_ROOT%\core\agents\*.md") do (
  copy /Y "%%F" "%PROJECT_ROOT%\.claude\agents\_harness_%%~nxF" >nul
)

echo [Harness] Syncing skills ...
for /D %%D in ("%HARNESS_ROOT%\core\skills\*") do (
  set "TARGET=%PROJECT_ROOT%\.claude\skills\_harness_%%~nxD"
  if not exist "!TARGET!" mkdir "!TARGET!"
  xcopy /E /I /Y /Q "%%D" "!TARGET!" >nul
)

echo.
echo [Harness] ClaudeCode configuration applied for: %PROJECT_ROOT%

endlocal
