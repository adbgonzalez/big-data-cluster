$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$work = Join-Path $root "work"

if (-not (Test-Path $work)) {
  Write-Host "Non existe: $work"
  exit 0
}

Get-ChildItem -Path $work -Filter "kafka-wordcount-checkpoint*" -Force -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Host "Borrando $($_.FullName)"
  Remove-Item -Recurse -Force $_.FullName
}

Write-Host "Checkpoints borrados."
