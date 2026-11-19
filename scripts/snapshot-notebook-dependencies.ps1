param(
    [string]$NotebookImage = "adbgonzalez/spark-notebook:4.1.1-py312",
    [string]$SparkImage = "adbgonzalez/spark:4.1.1-py312",
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "../jupyter/baseline")
)

$ErrorActionPreference = "Stop"

function Get-ImageIdentity([string]$Reference) {
    $raw = docker image inspect $Reference
    if ($LASTEXITCODE -ne 0) { throw "Non se pode inspeccionar a imaxe local: $Reference" }
    $image = @($raw | ConvertFrom-Json)[0]
    return [ordered]@{
        reference = $Reference
        id = $image.Id
        repo_digests = @($image.RepoDigests)
        created = $image.Created
        os = $image.Os
        architecture = $image.Architecture
    }
}

# Refuse to replace an earlier baseline accidentally.
if (Test-Path -LiteralPath $OutputDirectory) {
    throw "Xa existe $OutputDirectory. Indica outro -OutputDirectory para unha nova captura."
}

$notebook = Get-ImageIdentity $NotebookImage
$spark = Get-ImageIdentity $SparkImage
$inspector = Get-Content -LiteralPath (Join-Path $PSScriptRoot "inspect-python-environment.py") -Raw

# Inspect the resolved image ID, with no downloads, mounts or network access.
$rawEnvironment = $inspector | docker run --rm -i --pull never --network none --entrypoint python3 $notebook.id -
if ($LASTEXITCODE -ne 0) { throw "Fallou a captura do contorno do notebook." }
$environment = $rawEnvironment | ConvertFrom-Json
if ($environment.pip_freeze.exit_code -ne 0) { throw "Fallou pip freeze." }

$baseline = [ordered]@{
    captured_at_utc = [DateTime]::UtcNow.ToString("o")
    notebook_image = $notebook
    spark_image_local_reference = $spark
    note = "A referencia Spark local rexistrase por separado; non acredita a procedencia historica da imaxe notebook."
    environment = $environment
}

# Constraints preserve pip-managed packages. OS packages remain in the inventory,
# but must not be reinstalled from PyPI (some have Ubuntu-specific versions).
$constraints = @(
    "# Existing pip-managed notebook packages, before adding GX."
    "# This is a constraints file, not a complete installation requirements file."
    "# Keep OS-managed packages in the base image; see notebook-baseline.json."
    $environment.packages |
        Where-Object { $_.installer -eq "pip" -and -not $_.direct_url } |
        ForEach-Object { "$($_.name)==$($_.version)" }
)

$utf8 = New-Object System.Text.UTF8Encoding($false)
$directory = [System.IO.Directory]::CreateDirectory($OutputDirectory).FullName
[System.IO.File]::WriteAllText(
    (Join-Path $directory "notebook-baseline.json"),
    (($baseline | ConvertTo-Json -Depth 12) + "`n"), $utf8
)
[System.IO.File]::WriteAllText(
    (Join-Path $directory "constraints-existing.txt"),
    (($constraints -join "`n") + "`n"), $utf8
)
[System.IO.File]::WriteAllText(
    (Join-Path $directory "requirements.freeze.txt"),
    ("# Full inventory, including OS packages; do not install this file directly.`n" +
        $environment.pip_freeze.stdout.Replace("`r`n", "`n") + "`n"), $utf8
)

Write-Host "Captura gardada en $directory"
Write-Host "Paquetes rexistrados: $(@($environment.packages).Count)"
if ($environment.pip_check.exit_code -ne 0) {
    Write-Warning "pip check xa detecta incidencias na imaxe actual; quedan rexistradas no JSON."
    Write-Host $environment.pip_check.stdout
}
