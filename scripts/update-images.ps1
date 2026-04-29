$ErrorActionPreference = "Stop"

$Images = @(
  "adbgonzalez/spark:4.1.1-py312",
  "adbgonzalez/spark-notebook:4.1.1-py312",
  "adbgonzalez/hadoop:3.4.3-py312",
  "adbgonzalez/kafka:3.9",
  "adbgonzalez/airflow:3.1.8"
)

foreach ($Image in $Images) {
  Write-Host ""
  Write-Host "> docker pull $Image"
  docker pull $Image

  if ($LASTEXITCODE -ne 0) {
    throw "Fallou docker pull $Image"
  }
}

Write-Host ""
Write-Host "Imaxes actualizadas."
