param(
    [string]$Destination = (Join-Path $PSScriptRoot '..\entorno_bda\images')
)

$ErrorActionPreference = 'Stop'
$groups = [ordered]@{
    exame1 = @(
    'adbgonzalez/spark:4.1.1-py312',
    'adbgonzalez/spark-notebook:4.1.1-py312',
    'postgres:16',
    'chrislusf/seaweedfs:4.48',
    'public.ecr.aws/aws-cli/aws-cli:2.27.41'
    )
    exame2 = @(
    'adbgonzalez/kafka:3.9',
    'redpandadata/console:latest'
    )
    exame3 = @(
    'adbgonzalez/airflow:3.1.8',
    'adbgonzalez/superset:6.0',
    'redis:7'
    )
}
$images = @($groups.Values | ForEach-Object { $_ })

$Destination = (Resolve-Path -LiteralPath $Destination).Path
foreach ($group in $groups.Keys) {
    $archive = Join-Path $Destination "$group-images.tar"
    if ((Test-Path -LiteralPath $archive) -or (Test-Path -LiteralPath "$archive.partial")) {
        throw "Xa existe unha exportacion de $group. Non se sobrescribe."
    }
}

foreach ($image in $images) {
    $ErrorActionPreference = 'Continue'
    docker image inspect $image *> $null
    $missing = $LASTEXITCODE -ne 0
    $ErrorActionPreference = 'Stop'
    if ($missing) {
        $drive = [System.IO.DriveInfo]::new([System.IO.Path]::GetPathRoot($Destination))
        if ($drive.AvailableFreeSpace -lt 15GB) { throw 'Quedan menos de 15 GB libres; detense a descarga.' }
        # Nunca substituimos unha imaxe local xa validada por outra remota.
        Write-Host "Descargando a imaxe que falta: $image"
        docker pull --platform linux/amd64 $image
        if ($LASTEXITCODE -ne 0) { throw "Non se puido descargar $image" }
    }
}

$inspection = docker image inspect @images
if ($LASTEXITCODE -ne 0) { throw 'Non se puideron inspeccionar as imaxes.' }
$details = ($inspection -join "`n") | ConvertFrom-Json
$estimatedSize = ($details | Measure-Object -Property Size -Sum).Sum
$drive = [System.IO.DriveInfo]::new([System.IO.Path]::GetPathRoot($Destination))
if ($drive.AvailableFreeSpace -lt ($estimatedSize + 5GB)) {
    throw 'Non hai espazo suficiente para a estimacion conservadora do TAR mais 5 GB de marxe.'
}

$checksums = @()
foreach ($group in $groups.Keys) {
    $groupImages = $groups[$group]
    $archive = Join-Path $Destination "$group-images.tar"
    $partial = "$archive.partial"
    Write-Host "Exportando $group..."
    docker image save --output $partial @groupImages
    if ($LASTEXITCODE -ne 0) { throw "Fallou a exportacion. Arquivo incompleto: $partial" }
    Move-Item -LiteralPath $partial -Destination $archive

    $manifest = foreach ($image in $groupImages) {
        $index = [array]::IndexOf($images, $image)
        [pscustomobject]@{
            image = $image
            id = $details[$index].Id
            os = $details[$index].Os
            architecture = $details[$index].Architecture
        }
    }
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $Destination "$group-manifest.json") -Encoding UTF8
    Write-Host "Calculando SHA256 de $group..."
    $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksums += "$hash  $group-images.tar"
    $checksums | Set-Content -LiteralPath (Join-Path $Destination 'SHA256SUMS.txt') -Encoding ASCII
    Get-Item -LiteralPath $archive | Select-Object Name, Length
}
Write-Host 'Exportacion rematada.'
