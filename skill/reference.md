# Reference: Scripts & Site Patterns

## scripts/send-long-prompt.ps1

```powershell
param(
  [Parameter(Mandatory)][string]$PromptFile,
  [string]$Ref = "",           # e.g. @e3; if empty, uses current focus
  [switch]$UseInsertText
)
$text = [IO.File]::ReadAllText($PromptFile).Replace("`r`n", "`n")
if ($UseInsertText) {
  if ($Ref) { agent-browser click $Ref }
  # Escape for shell: write to temp and use node to pass to CLI
  $tmp = [IO.Path]::GetTempFileName()
  Set-Content -Path $tmp -Value $text -NoNewline -Encoding UTF8
  agent-browser keyboard inserttext (Get-Content -Raw $tmp)
  Remove-Item $tmp
} else {
  Set-Clipboard -Value $text
  if ($Ref) { agent-browser click $Ref } else { Write-Host "Focus target first" }
  Start-Sleep -Milliseconds 300
  agent-browser clipboard paste
}
agent-browser snapshot -i
```

## scripts/wait-task-complete.ps1

```powershell
param(
  [string]$Selector = "body",
  [int]$StableSeconds = 2,
  [int]$MaxWaitSeconds = 180,
  [string]$StopIndicator = "Stop"
)
$prev = ""
$stableSince = $null
$deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
while ((Get-Date) -lt $deadline) {
  $cur = agent-browser get text $Selector 2>$null
  if ($cur -eq $prev) {
    if (-not $stableSince) { $stableSince = Get-Date }
    if (((Get-Date) - $stableSince).TotalSeconds -ge $StableSeconds) {
      $body = agent-browser eval --fn "document.body.innerText" 2>$null
      if ($body -notmatch $StopIndicator) { Write-Output "COMPLETE"; exit 0 }
    }
  } else {
    $prev = $cur
    $stableSince = $null
  }
  Start-Sleep -Seconds 1
}
Write-Error "TIMEOUT"; exit 1
```

## scripts/get-full-response.ps1

```powershell
param(
  [string]$Selector = "[data-message-author-role=assistant]",
  [string]$OutFile = "reply.txt"
)
# Scroll to load lazy content
1..5 | ForEach-Object { agent-browser scroll down 1500; Start-Sleep -Milliseconds 500 }
agent-browser scroll up 800
$text = agent-browser eval --fn @"
(() => {
  const nodes = document.querySelectorAll('$($Selector.Replace("'","\\'"))');
  if (!nodes.length) return document.body.innerText;
  return [...nodes].map(n => n.innerText).join('\n\n---\n\n');
})()
"@
Set-Content -Path $OutFile -Value $text -Encoding UTF8
Write-Output "Saved $($text.Length) chars to $OutFile"
```

## Common LLM UI selectors (verify per site)

| Site | Input | Send | Assistant message |
|------|-------|------|-------------------|
| ChatGPT | `#prompt-textarea`, `[contenteditable]` | `[data-testid=send-button]` | `[data-message-author-role=assistant]` |
| Claude | `.ProseMirror`, `div[contenteditable]` | `button[aria-label*=Send]` | `.font-claude-message` |
| Gemini | `rich-textarea`, `.ql-editor` | `button[aria-label*=Send]` | `message-content` |

Always confirm with `agent-browser snapshot -i` — selectors change.

## agent-browser commands quick ref

| Task | Command |
|------|---------|
| Multiline paste | `clipboard write` + `clipboard paste` |
| No-key-event insert | `keyboard inserttext <text>` |
| Wait for text | `wait --text "substring"` |
| Wait for JS | `wait --fn "condition"` |
| Wait network | `wait --load networkidle` |
| Get text | `get text <sel>` |
| Full page text | `eval --fn "document.body.innerText"` |
| Stable check | `diff snapshot` |
| Structured chat | `chat --json` (needs AI_GATEWAY_API_KEY) |

## Install upstream skill in Cursor

```bash
npx skills add vercel-labs/agent-browser
```

Copy this repo's `skill/` to `~/.cursor/skills/agent-browser-enhanced/` for the three enhanced workflows.
