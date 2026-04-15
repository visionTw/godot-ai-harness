@echo off
setlocal

set HARNESS_ROOT=%~dp0..
set PROJECT_ROOT=%CD%

if not exist "%PROJECT_ROOT%\\.claude" mkdir "%PROJECT_ROOT%\\.claude"

copy /Y "%HARNESS_ROOT%\\adapters\\claudecode\\CLAUDE.template.md" "%PROJECT_ROOT%\\.claude\\CLAUDE.md" >nul
copy /Y "%HARNESS_ROOT%\\adapters\\claudecode\\mcp.template.json" "%PROJECT_ROOT%\\.claude\\mcp.json" >nul

echo [Harness] ClaudeCode configuration applied.
echo - Project: %PROJECT_ROOT%
echo - CLAUDE: %PROJECT_ROOT%\.claude\CLAUDE.md
echo - MCP: %PROJECT_ROOT%\.claude\mcp.json

endlocal
