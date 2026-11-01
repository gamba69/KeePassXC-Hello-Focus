# Download a fresh copy of the latest stable AutoIt portable toolchain for each build.
# Never use an installed compiler, a previous download, or AUT2EXE_PATH.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$toolsRoot = Join-Path $root '.tools\AutoIt'
$buildTemp = Join-Path $root '.build'
$officialPortableUrl = 'https://www.autoitscript.com/files/autoit3/autoit-v3.zip'

function Find-Compiler([string]$directory) {
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { return $null }
    foreach ($relativePath in @(
        'install\Aut2Exe\Aut2exe_x64.exe',
        'Aut2Exe\Aut2exe_x64.exe',
        'install\Aut2Exe\Aut2exe.exe',
        'Aut2Exe\Aut2exe.exe'
    )) {
        $candidate = Join-Path $directory $relativePath
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    # Find the compiler even if the vendor adds a wrapper directory.
    $files = @(Get-ChildItem -LiteralPath $directory -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ieq 'Aut2exe_x64.exe' -or $_.Name -ieq 'Aut2exe.exe' } |
        Sort-Object @{ Expression = { if ($_.Name -ieq 'Aut2exe_x64.exe') { 0 } else { 1 } } }, FullName)
    foreach ($file in $files) {
        $runtimeDir = Split-Path (Split-Path $file.FullName -Parent) -Parent
        if ((Test-Path -LiteralPath (Join-Path $runtimeDir 'AutoIt3_x64.exe') -PathType Leaf) -or
            (Test-Path -LiteralPath (Join-Path $runtimeDir 'AutoIt3.exe') -PathType Leaf)) {
            return $file.FullName
        }
    }
    return $null
}

function Get-Runtime([string]$compiler) {
    $autoItDir = Split-Path (Split-Path $compiler -Parent) -Parent
    foreach ($name in @('AutoIt3_x64.exe', 'AutoIt3.exe')) {
        $runtime = Join-Path $autoItDir $name
        if (Test-Path -LiteralPath $runtime -PathType Leaf) { return $runtime }
    }
    throw 'AutoIt runtime is missing from the downloaded portable package.'
}

# Create a uniquely named staging directory; existing toolchains are never consulted.
New-Item -ItemType Directory -Path $buildTemp -Force | Out-Null
$stage = Join-Path $buildTemp ('autoit-download-' + [guid]::NewGuid().ToString('N'))
$downloadFile = Join-Path $stage 'autoit-v3.zip'
$extractDir = Join-Path $stage 'extracted'
New-Item -ItemType Directory -Path $stage -Force | Out-Null

try {
    Write-Host 'Downloading the latest stable AutoIt portable package from the official website (every build)...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $officialPortableUrl -OutFile $downloadFile -UseBasicParsing -ErrorAction Stop
    if ((Get-Item -LiteralPath $downloadFile).Length -lt 1000000) {
        throw 'The downloaded AutoIt archive is unexpectedly small.'
    }

    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    Expand-Archive -LiteralPath $downloadFile -DestinationPath $extractDir -Force
    $compiler = Find-Compiler $extractDir
    if (-not $compiler) { throw 'The downloaded AutoIt package does not contain Aut2Exe.' }
    $runtime = Get-Runtime $compiler

    # Latest stable has no fixed SHA-256: verify the vendor-signed runtime instead.
    $signature = Get-AuthenticodeSignature -LiteralPath $runtime
    if ($signature.Status -ne 'Valid') {
        throw "AutoIt runtime signature validation failed: $($signature.Status)."
    }
    if ($null -eq $signature.SignerCertificate -or
        $signature.SignerCertificate.Subject -notmatch 'AutoIt Consulting') {
        throw 'The downloaded AutoIt runtime is not signed by AutoIt Consulting.'
    }

    $runtimeDir = Split-Path $runtime -Parent
    $checker = Join-Path $runtimeDir 'Au3Check.exe'
    if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
        throw 'The downloaded AutoIt package is missing Au3Check.exe.'
    }
    $runtimeVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($runtime).FileVersion
    if ([string]::IsNullOrWhiteSpace($runtimeVersion)) { $runtimeVersion = 'unknown' }

    # Replace any previous locally downloaded compiler ONLY after validation.
    # Never fall back to the old copy on download or signature failure.
    if (Test-Path -LiteralPath $toolsRoot) {
        Remove-Item -LiteralPath $toolsRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $toolsRoot -Force | Out-Null
    $destination = Join-Path $toolsRoot 'current'
    Move-Item -LiteralPath $extractDir -Destination $destination
    $compiler = Find-Compiler $destination
    if (-not $compiler) { throw 'Aut2Exe was not found after extracting the new package.' }

    Write-Host "Using newly downloaded AutoIt $runtimeVersion : $compiler"
    Write-Output (Resolve-Path -LiteralPath $compiler).Path
}
finally {
    if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    }
}
