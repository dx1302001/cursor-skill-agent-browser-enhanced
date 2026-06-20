param(
  [string]$Selector = "[data-message-author-role=assistant]",
  [string]$OutFile = "reply.txt"
)
$ErrorActionPreference = "Stop"
1..5 | ForEach-Object {
  agent-browser scroll down 1500 | Out-Null
  Start-Sleep -Milliseconds 500
}
agent-browser scroll up 800 | Out-Null
$escaped = $Selector.Replace("'", "\'")
$js = "(() => { const nodes = document.querySelectorAll('$escaped'); if (!nodes.length) return document.body.innerText; return [...nodes].map(n => n.innerText).join('\n\n---\n\n'); })()"
$text = agent-browser eval --fn $js
Set-Content -Path $OutFile -Value $text -Encoding UTF8
Write-Output "Saved $($text.Length) chars to $OutFile"
