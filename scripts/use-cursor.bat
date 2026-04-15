@echo off
setlocal

set HARNESS_ROOT=%~dp0..
set PROJECT_ROOT=%CD%

if not exist "%PROJECT_ROOT%\\.cursor" mkdir "%PROJECT_ROOT%\\.cursor"
if not exist "%PROJECT_ROOT%\\.cursor\\.npm-cache" mkdir "%PROJECT_ROOT%\\.cursor\\.npm-cache"

copy /Y "%HARNESS_ROOT%\\adapters\\cursor\\mcp.template.json" "%PROJECT_ROOT%\\.cursor\\mcp.json" >nul

echo [Harness] Cursor configuration applied.
echo - Project: %PROJECT_ROOT%
echo - MCP: %PROJECT_ROOT%\.cursor\mcp.json
echo.
echo Next: open Cursor MCP panel and enable godot server.

endlocal
