@echo off
setlocal enabledelayedexpansion

set HARNESS_ROOT=%~dp0..
set PROJECT_ROOT=%CD%

if "%~1"=="--project-root" (
  set PROJECT_ROOT=%~2
)

echo [Harness] Applying Cursor configuration...
echo   HARNESS_ROOT = %HARNESS_ROOT%
echo   PROJECT_ROOT = %PROJECT_ROOT%

if not exist "%PROJECT_ROOT%" (
  echo [Error] PROJECT_ROOT not found: %PROJECT_ROOT%
  exit /b 1
)

if not exist "%PROJECT_ROOT%\.cursor" mkdir "%PROJECT_ROOT%\.cursor"
if not exist "%PROJECT_ROOT%\.cursor\.npm-cache" mkdir "%PROJECT_ROOT%\.cursor\.npm-cache"
if not exist "%PROJECT_ROOT%\.cursor\rules" mkdir "%PROJECT_ROOT%\.cursor\rules"
if not exist "%PROJECT_ROOT%\.cursor\skills" mkdir "%PROJECT_ROOT%\.cursor\skills"
if not exist "%PROJECT_ROOT%\.cursor\commands" mkdir "%PROJECT_ROOT%\.cursor\commands"
if not exist "%PROJECT_ROOT%\.cursor\agents" mkdir "%PROJECT_ROOT%\.cursor\agents"

echo [Harness] Cleaning previous harness artifacts (_harness_*) ...
for %%F in ("%PROJECT_ROOT%\.cursor\rules\_harness_*.mdc") do del /Q "%%F" 2>nul
for %%F in ("%PROJECT_ROOT%\.cursor\commands\_harness_*.md") do del /Q "%%F" 2>nul
for %%F in ("%PROJECT_ROOT%\.cursor\agents\_harness_*.md") do del /Q "%%F" 2>nul
for /D %%D in ("%PROJECT_ROOT%\.cursor\skills\_harness_*") do rmdir /S /Q "%%D" 2>nul

echo [Harness] Syncing mcp.json ...
copy /Y "%HARNESS_ROOT%\adapters\cursor\mcp.template.json" "%PROJECT_ROOT%\.cursor\mcp.json" >nul

echo [Harness] Syncing rules ...
for %%F in ("%HARNESS_ROOT%\core\rules\*.mdc") do (
  set "NAME=%%~nF"
  set "PREFIX=!NAME:~0,9!"
  if /I "!PREFIX!"=="_harness_" (
    copy /Y "%%F" "%PROJECT_ROOT%\.cursor\rules\!NAME!.mdc" >nul
  ) else (
    copy /Y "%%F" "%PROJECT_ROOT%\.cursor\rules\_harness_!NAME!.mdc" >nul
  )
)

echo [Harness] Syncing commands ...
for %%F in ("%HARNESS_ROOT%\core\commands\*.md") do (
  copy /Y "%%F" "%PROJECT_ROOT%\.cursor\commands\_harness_%%~nxF" >nul
)

echo [Harness] Syncing agents ...
for %%F in ("%HARNESS_ROOT%\core\agents\*.md") do (
  copy /Y "%%F" "%PROJECT_ROOT%\.cursor\agents\_harness_%%~nxF" >nul
)

echo [Harness] Syncing skills ...
for /D %%D in ("%HARNESS_ROOT%\core\skills\*") do (
  set "TARGET=%PROJECT_ROOT%\.cursor\skills\_harness_%%~nxD"
  if not exist "!TARGET!" mkdir "!TARGET!"
  xcopy /E /I /Y /Q "%%D" "!TARGET!" >nul
)

echo.
echo [Harness] Cursor configuration applied for: %PROJECT_ROOT%
echo   - .cursor\mcp.json
echo   - .cursor\rules\_harness_*.mdc
echo   - .cursor\commands\_harness_*.md
echo   - .cursor\agents\_harness_*.md
echo   - .cursor\skills\_harness_*\
echo.
echo Next: open Cursor MCP panel and enable godot server.

endlocal
