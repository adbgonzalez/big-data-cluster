param()

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$packageRoot = Join-Path $sourceRoot 'entorno_bda'
$clusterTarget = Join-Path $packageRoot 'big-data-lab\big-data-cluster'
$notebooksSource = Join-Path (Split-Path -Parent $sourceRoot) 'spark-notebooks'
$notebooksTarget = Join-Path $packageRoot 'big-data-lab\spark-notebooks'
$utf8 = [System.Text.UTF8Encoding]::new($false)

if (-not (Test-Path -LiteralPath $notebooksSource -PathType Container)) {
    throw "Non existe $notebooksSource"
}
foreach ($n in 1..3) {
    if (-not (Test-Path -LiteralPath (Join-Path $packageRoot "images\exame$n-images.tar") -PathType Leaf)) {
        throw "Falta images\exame$n-images.tar. Prepara primeiro as imaxes."
    }
}

New-Item -ItemType Directory -Force -Path $clusterTarget, $notebooksTarget | Out-Null
$runtimeFiles = @(
    '.env', 'compose.base.yml', 'compose.postgres.yml', 'compose.seaweedfs.yml',
    'compose.kafka.yml', 'compose.airflow.yml', 'compose.superset.yml',
    'start-dfs.sh', 'start-history.sh', 'instrucions_exame.md',
    'instrucions_exame1.md', 'instrucions_exame2.md', 'instrucions_exame3.md'
)
foreach ($file in $runtimeFiles) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination $clusterTarget -Force
}
foreach ($dir in @('conf', 'spark-conf', 'airflow\dags', 'airflow\config', 'airflow\plugins', 'airflow\logs')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $clusterTarget $dir) | Out-Null
}
Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'conf') -File -Filter '*.xml' |
    Copy-Item -Destination (Join-Path $clusterTarget 'conf') -Force
foreach ($file in @('spark-defaults.conf', 'spark-defaults-airflow.conf')) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot "spark-conf\$file") -Destination (Join-Path $clusterTarget 'spark-conf') -Force
}
foreach ($dir in @('dags', 'config', 'plugins')) {
    $source = Join-Path $sourceRoot "airflow\$dir"
    robocopy $source (Join-Path $clusterTarget "airflow\$dir") /E /XD __pycache__ /XF *.pyc /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Fallou a copia de airflow\$dir" }
}

# Copia os notebooks de consulta; o cartafol probas queda fora.
# Non copia repositorios Git, papeleiras, checkpoints nin caches Python.
robocopy $notebooksSource $notebooksTarget /E /XD .git .Trash-1000 .ipynb_checkpoints __pycache__ (Join-Path $notebooksSource 'probas') /XF *.pyc /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw 'Fallou a copia dos notebooks' }

# Os scripts montados en Linux deben ter finais de lina LF.
Get-ChildItem -LiteralPath $clusterTarget -Recurse -File | Where-Object {
    $_.Extension -in @('.sh', '.yml', '.conf', '.xml', '.py') -or $_.Name -eq '.env'
} | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName).Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText($_.FullName, $content, $utf8)
}

$notebook = @{
    nbformat = 4
    nbformat_minor = 5
    metadata = @{
        kernelspec = @{ display_name = 'Python 3 (ipykernel)'; language = 'python'; name = 'python3' }
        language_info = @{ name = 'python'; version = '3.12' }
    }
    cells = @(
        @{
            id = 'instrucions'; cell_type = 'markdown'; metadata = @{}
            source = @("# Comprobar o contorno`n", "Executa a seguinte cela. Debe mostrar yarn e 10. A primeira execucion pode tardar.")
        },
        @{
            id = 'spark-yarn'; cell_type = 'code'; metadata = @{}; execution_count = $null; outputs = @()
            source = @(
                "from pyspark.sql import SparkSession`n",
                "spark = SparkSession.builder.getOrCreate()`n",
                "print(spark.sparkContext.master)`n",
                'print(spark.range(10).count())'
            )
        }
    )
}
[System.IO.File]::WriteAllText((Join-Path $notebooksTarget '00-comprobar-contorno.ipynb'), ($notebook | ConvertTo-Json -Depth 20), $utf8)

foreach ($file in @('instrucions_exame.md', 'instrucions_exame1.md', 'instrucions_exame2.md', 'instrucions_exame3.md')) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination $packageRoot -Force
}
$readme = @'
# Contorno BDA: proba local

1. Copia esta carpeta completa na unidade D:, de xeito que quede `D:\entorno_bda`.
2. Abre Docker Desktop en modo Linux.
3. Sigue `instrucions_exame1.md`, `instrucions_exame2.md` ou `instrucions_exame3.md`.
4. En Jupyter podes executar `00-comprobar-contorno.ipynb` para comprobar Spark sobre YARN.

Estrutura:

```text
D:\entorno_bda\
  images\
    exame1-images.tar
    exame2-images.tar
    exame3-images.tar
  big-data-lab\
    big-data-cluster\
    spark-notebooks\
  instrucions_exame1.md
  instrucions_exame2.md
  instrucions_exame3.md
```

Incluense os exemplos e tarefas de consulta. O cartafol `probas`, que conten as solucions de proba, queda fora do paquete.

As imaxes estan preparadas para funcionar sen descargas. A instalacion completa nun equipo limpo queda pendente desta proba.

Se probas no mesmo Docker que o contorno habitual, o proxecto `bda` reutiliza os seus contedores e volumes. Copiar a carpeta a D: non illa os datos de Docker. O HDFS habitual ten unha incidencia pendente de revision; para unha proba limpa usa outro equipo cun Docker sen ese contorno.
'@
[System.IO.File]::WriteAllText((Join-Path $packageRoot 'LEME.md'), $readme.Replace("`r`n", "`n"), $utf8)
Write-Host "Preparado: $packageRoot"
Write-Host 'Non se arrancaron servizos nin se modificaron volumes de Docker.'
# Robocopy usa codigos 1-7 para copias correctas.
$global:LASTEXITCODE = 0
