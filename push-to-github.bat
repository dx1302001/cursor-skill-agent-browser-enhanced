@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo === agent-browser-enhanced GitHub Upload ===

gh auth status >nul 2>&1
if errorlevel 1 (
  echo [1/3] Login GitHub...
  gh auth login
)

echo [2/3] Create repo and push...
gh repo view dx1302001/cursor-skill-agent-browser-enhanced >nul 2>&1
if errorlevel 1 (
  gh repo create cursor-skill-agent-browser-enhanced --public --source=. --remote=origin --push --description "Cursor skill: agent-browser enhanced - long prompts, task completion, full reply capture"
) else (
  git push -u origin master 2>nul || git push -u origin main
)

echo.
echo Done: https://github.com/dx1302001/cursor-skill-agent-browser-enhanced
pause
