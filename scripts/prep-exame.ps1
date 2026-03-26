# scripts\prep-exame.ps1
# Carga as imaxes do tar + arrinca o cluster + importa a caché Ivy no notebook.
#
# Requisitos:
# - Os tar están en: D:\exames-bigdata
#   - D:\exames-bigdata\bda-core-images.tar
#   - D:\exames-bigdata\ivy2-offline.tar
#
# Execución recomendada (sen cambiar políticas do sistema):
#   powershell -ExecutionPolicy Bypass -File .\scripts\prep-exame.ps1

$ErrorActionPreference = "Stop"

Write-Host "== Preparacion do contorno (BDA) =="

# Ir ao directorio raiz do repo (pai de /scripts)
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

# Rutas dos TAR (fixas en D:\exames-bigdata)
$tarDir   = "D:\exames-bigdata"
$imagesTar = Join-Path $tarDir "bda-core-images.tar"
$ivyTar    = Join-Path $tarDir "ivy2-offline.tar"

if (-not (Test-Path $imagesTar)) { throw "Non se atopa: $imagesTar" }
if (-not (Test-Path $ivyTar))    { throw "Non se atopa: $ivyTar" }

# Comprobar que Docker esta en Linux containers
$osType = docker info --format "{{.OSType}}" 2>$null
if ($LASTEXITCODE -ne 0) { throw "Docker non responde. Asegurarse de que Docker Desktop esta iniciado." }
if ($osType.Trim() -ne "linux") { throw "Docker esta en modo '$osType'. Cambiar Docker Desktop a Linux containers e volver executar." }

Write-Host "1) Cargando imaxes Docker desde $imagesTar ..."
docker load -i $imagesTar | Out-Host

Write-Host "2) Arrincando o cluster (compose.base + compose.kafka) ..."
docker compose -f compose.base.yml -f compose.kafka.yml up -d | Out-Host

Write-Host "3) Agardando a que exista o contedor 'spark-notebook' ..."
$maxWaitSec = 60
$start = Get-Date
while ($true) {
  $exists = docker ps -a --format "{{.Names}}" | Select-String -SimpleMatch "spark-notebook"
  if ($exists) { break }
  if (((Get-Date) - $start).TotalSeconds -gt $maxWaitSec) {
    throw "Non apareceu 'spark-notebook' en $maxWaitSec s. Revisa: docker compose ps / docker logs spark-notebook"
  }
  Start-Sleep -Seconds 2
}

Write-Host "4) Importando caché Ivy no contedor (desde $ivyTar) ..."
docker cp $ivyTar spark-notebook:/tmp/ivy2-offline.tar | Out-Host
docker exec spark-notebook bash -lc "tar -C /home/hadoop -xf /tmp/ivy2-offline.tar && chown -R 1000:1000 /home/hadoop/.ivy2" | Out-Host

Write-Host "5) Proba rapida (Spark non deberia descargar nada) ..."
docker exec -u 1000:1000 spark-notebook bash -lc "spark-shell -e 'println(""ivy ok"")'" | Out-Host

Write-Host ""
Write-Host "Listo. Abrir no navegador: http://localhost:8888"
Write-Host "Para parar todo: powershell -ExecutionPolicy Bypass -File .\scripts\down-all.ps1"
