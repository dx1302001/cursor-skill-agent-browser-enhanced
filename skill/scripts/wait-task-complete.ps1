param(
  [string]$Selector = "body",
  [int]$StableSeconds = 2,
  [int]$MaxWaitSeconds = 180,
  [string]$StopPattern = "Stop|停止|Generating|正在生成"
)
$ErrorActionPreference = "Stop"
$prev = ""
$stableSince = $null
$deadline = (Get-Date).AddSeconds($MaxWaitSeconds)
while ((Get-Date) -lt $deadline) {
  $cur = (agent-browser get text $Selector 2>$null) -join ""
  if ($cur -eq $prev -and $cur.Length -gt 0) {
    if (-not $stableSince) { $stableSince = Get-Date }
    if (((Get-Date) - $stableSince).TotalSeconds -ge $StableSeconds) {
      $body = agent-browser eval --fn "document.body.innerText" 2>$null
      if ($body -notmatch $StopPattern) {
        Write-Output "COMPLETE"
        exit 0
      }
    }
  } else {
    $prev = $cur
    $stableSince = $null
  }
  Start-Sleep -Seconds 1
}
Write-Error "TIMEOUT after ${MaxWaitSeconds}s"
exit 1
