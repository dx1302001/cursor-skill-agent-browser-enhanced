param(
  [Parameter(Mandatory)][string]$PromptFile,
  [string]$Ref = "",
  [switch]$UseInsertText
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $PromptFile)) { throw "File not found: $PromptFile" }
$text = [IO.File]::ReadAllText($PromptFile).Replace("`r`n", "`n")
if ($UseInsertText) {
  if ($Ref) { agent-browser click $Ref }
  agent-browser keyboard inserttext $text
} else {
  Set-Clipboard -Value $text
  if ($Ref) { agent-browser click $Ref }
  Start-Sleep -Milliseconds 300
  agent-browser clipboard paste
}
agent-browser snapshot -i
