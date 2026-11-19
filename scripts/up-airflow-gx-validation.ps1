$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    $composeFiles = @("-f", "compose.base.yml", "-f", "compose.airflow.yml", "-f", "compose.airflow-gx-validation.yml")
    $airflowImageId = docker image ls --quiet adbgonzalez/airflow:3.1.8
    if ($LASTEXITCODE -ne 0 -or -not $airflowImageId) { throw "Falta a imaxe local. Construir con: docker build --platform linux/amd64 -t adbgonzalez/airflow:3.1.8 ./airflow" }

    docker compose @composeFiles up -d --pull never --no-build --wait --wait-timeout 180 namenode datanode resourcemanager nodemanager airflow-db
    if ($LASTEXITCODE -ne 0) { throw "Non se puideron arrancar as dependencias." }

    $ready = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        # Windows PowerShell treats native stderr as an error even when redirected.
        # A refused connection is expected while NameNode is still starting.
        $ErrorActionPreference = "Continue"
        docker exec namenode hdfs dfs -test -d / *> $null
        $probeExit = $LASTEXITCODE
        $safeState = docker exec namenode hdfs dfsadmin -safemode get 2>&1
        $safeExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($probeExit -eq 0 -and $safeExit -eq 0 -and ($safeState -match "Safe mode is OFF")) { $ready = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) { throw "HDFS non esta preparado." }
    docker exec namenode hdfs dfs -mkdir -p /tmp/gx-airflow-validation
    if ($LASTEXITCODE -ne 0) { throw "Non se puido crear o directorio HDFS da proba." }
    docker exec namenode hdfs dfs -chown airflow:supergroup /tmp/gx-airflow-validation
    if ($LASTEXITCODE -ne 0) { throw "Non se puido preparar o propietario do directorio de proba." }

    docker compose @composeFiles run --rm --no-deps --pull never airflow-init
    if ($LASTEXITCODE -ne 0) { throw "Fallou a inicializacion de Airflow." }
    docker compose @composeFiles run --rm --no-deps --pull never airflow-init airflow pools set gx_yarn_validation 1 "Probas GX sobre YARN, unha de cada vez"
    if ($LASTEXITCODE -ne 0) { throw "Non se puido preparar a execucion secuencial das probas." }
    docker compose @composeFiles up -d --pull never --no-build airflow-api-server airflow-scheduler airflow-dag-processor
    if ($LASTEXITCODE -ne 0) { throw "Non se puido arrancar Airflow coa candidata." }
    Write-Host "Abrir http://localhost:8091 e agardar polos DAGs gx_yarn_correctos e gx_yarn_con_erros."
    Write-Host "Activar e executar primeiro correctos (debe pasar) e despois con_erros (debe fallar por GX)."
} finally {
    Pop-Location
}
