# cursor-skill-agent-browser-enhanced

Cursor Agent Skill：**在 [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) 基础上增强三大能力**

1. **长文本 / 多行 Prompt 不掉行** — clipboard paste、inserttext、文件注入
2. **判断任务是否完成** — 文本稳定轮询、Stop 按钮消失、networkidle、snapshot diff
3. **获取完整回复内容** — 滚动加载、多气泡拼接、落盘保存

## Prerequisites

```bash
npm install -g agent-browser
agent-browser install
agent-browser doctor
```

## Install this skill

```powershell
git clone https://github.com/dx1302001/cursor-skill-agent-browser-enhanced.git
$dest = "$env:USERPROFILE\.cursor\skills\agent-browser-enhanced"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path ".\skill\*" -Destination $dest -Recurse -Force
```

## Usage in Cursor

```
用 agent-browser-enhanced skill，打开 ChatGPT，发送 prompt.txt 里的长文本，等回复完成后把全文保存到 reply.txt
```

## Three helper scripts

| Script | Purpose |
|--------|---------|
| `skill/scripts/send-long-prompt.ps1` | 从文件发送多行 prompt |
| `skill/scripts/wait-task-complete.ps1` | 轮询直到回复稳定 |
| `skill/scripts/get-full-response.ps1` | 滚动并导出完整回复 |

Example:

```powershell
agent-browser open https://chat.openai.com
agent-browser snapshot -i
.\skill\scripts\send-long-prompt.ps1 -PromptFile .\prompt.txt -Ref "@e3"
agent-browser click @e_SEND
.\skill\scripts\wait-task-complete.ps1 -MaxWaitSeconds 300
.\skill\scripts\get-full-response.ps1 -OutFile reply.txt
```

## Repository structure

```
├── README.md
├── LICENSE
├── push-to-github.bat
└── skill/
    ├── SKILL.md
    ├── reference.md
    └── scripts/
        ├── send-long-prompt.ps1
        ├── wait-task-complete.ps1
        └── get-full-response.ps1
```

## Upstream

- agent-browser: https://github.com/vercel-labs/agent-browser
- Upstream skill: `agent-browser skills get core`

## License

MIT (this skill). agent-browser is Apache-2.0.

## Push to GitHub

```bash
cd cursor-skill-agent-browser-enhanced
gh auth login
gh repo create cursor-skill-agent-browser-enhanced --public --source=. --remote=origin --push
```

Or run `push-to-github.bat`.
