# Build KeePassXC Hello Focus with an explicit AutoIt compiler and icon.
# Example: .\scripts\Build.ps1 -Package -Tag v0.1.0
[CmdletBinding()]
param(
    [switch]$Package,
    [string]$Tag = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$name = 'KeePassXCHelloFocus'
$source = Join-Path $root "$name.au3"
$icon = Join-Path $root "$name.ico"
$trayIcon = Join-Path $root "${name}Tray.ico"
$dist = Join-Path $root 'dist'
$logsDir = Join-Path $root '.build\logs'
$exe = Join-Path $dist "$name.exe"

foreach ($path in @($source, $icon, $trayIcon)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required build input: $path"
    }
}

# Validate metadata before compilation. FileVersion is the authoritative version.
$au3 = Get-Content -LiteralPath $source -Raw -Encoding UTF8

# Keep the output location and application icon under control of this script.
# If these settings also appear as AutoIt pragmas, Aut2Exe can direct the
# compiled executable somewhere other than dist/ despite the /out option.
foreach ($option in @('Out', 'Icon')) {
    if ($au3 -match "(?im)^\s*#pragma\s+compile\(\s*$option\s*,") {
        throw "Remove the #pragma compile($option, ...) directive from the source. Build.ps1 owns /out and /icon."
    }
}
$versionMatch = [regex]::Match($au3, '(?m)^#pragma\s+compile\(FileVersion,\s*(\d+\.\d+\.\d+\.\d+)\)')
$productMatch = [regex]::Match($au3, '(?m)^#pragma\s+compile\(ProductVersion,\s*(\d+\.\d+\.\d+\.\d+)\)')
if (-not $versionMatch.Success -or -not $productMatch.Success) {
    throw 'Both FileVersion and ProductVersion must be declared in the AutoIt source.'
}
$version = $versionMatch.Groups[1].Value
if ($productMatch.Groups[1].Value -ne $version) { throw 'FileVersion and ProductVersion do not match.' }
$semanticMatch = [regex]::Match($version, '^(\d+\.\d+\.\d+)\.0$')
if (-not $semanticMatch.Success) { throw 'Expected version MAJOR.MINOR.PATCH.0.' }
$semver = $semanticMatch.Groups[1].Value
if ($Tag -and $Tag -cne "v$semver") {
    throw "Git tag '$Tag' does not match executable version 'v$semver'."
}

# Always download the latest stable portable AutoIt for every build; never use installed or cached versions.
$compiler = & (Join-Path $PSScriptRoot 'Get-AutoIt.ps1')
if (-not $compiler -or -not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw 'Could not download the latest stable AutoIt compiler.'
}

# Aut2Exe is a Windows GUI program. Invoking it with the PowerShell call
# operator can return before it exits and leave $LASTEXITCODE unset.
# Start-Process -Wait -PassThru provides a reliable process exit code.
function Quote-ProcessArgument([string]$value) {
    if ($value.Contains('"')) { throw 'A build path contains an unsupported double quote.' }
    return '"' + $value + '"'
}

function Invoke-BuildProcess {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$LogName
    )

    $stdoutPath = Join-Path $logsDir "$LogName.stdout.log"
    $stderrPath = Join-Path $logsDir "$LogName.stderr.log"
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue

    $process = Start-Process -FilePath $Path -ArgumentList $Arguments `
        -WorkingDirectory $root -Wait -PassThru `
        -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    foreach ($logPath in @($stdoutPath, $stderrPath)) {
        if ((Test-Path -LiteralPath $logPath -PathType Leaf) -and
            (Get-Item -LiteralPath $logPath).Length -gt 0) {
            Get-Content -LiteralPath $logPath | ForEach-Object { Write-Host $_ }
        }
    }
    if ($null -eq $process) { throw "Could not start $LogName." }
    return [int]$process.ExitCode
}

# dist is a clean, flat distribution directory, not a build workspace.
# Never retain stale executables or logs from earlier builds.
if (Test-Path -LiteralPath $dist) {
    Remove-Item -LiteralPath $dist -Recurse -Force
}
New-Item -ItemType Directory -Path $dist -Force | Out-Null
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
Get-ChildItem -LiteralPath $logsDir -File -Filter '*.log' -ErrorAction SilentlyContinue |
    Remove-Item -Force

Write-Host "AutoIt compiler: $compiler"
Write-Host "Release version: v$semver"

# Check source syntax with the checker bundled with the same AutoIt release.
$autoItRoot = Split-Path (Split-Path $compiler -Parent) -Parent
$checker = Join-Path $autoItRoot 'Au3Check.exe'
if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
    throw "Au3Check.exe is missing from the freshly downloaded AutoIt package: $autoItRoot"
}
Write-Host 'Checking AutoIt source syntax...'
$checkExit = Invoke-BuildProcess -Path $checker -Arguments @('-q', (Quote-ProcessArgument $source)) -LogName 'au3check'
if ($checkExit -ge 2) {
    throw "Au3Check reported syntax errors (exit code $checkExit). See .build\logs\au3check.stdout.log and .build\logs\au3check.stderr.log."
}
if ($checkExit -eq 1) { Write-Warning 'Au3Check reported warnings; proceeding with compilation.' }

Write-Host 'Compiling and waiting for Aut2Exe to finish...'
$compileExit = Invoke-BuildProcess -Path $compiler -Arguments @(
    '/in', (Quote-ProcessArgument $source),
    '/out', (Quote-ProcessArgument $exe),
    '/icon', (Quote-ProcessArgument $icon),
    '/x64', '/nopack'
) -LogName 'aut2exe'
if ($compileExit -ne 0) {
    throw "Aut2Exe failed (exit code $compileExit). See .build\logs\aut2exe.stdout.log and .build\logs\aut2exe.stderr.log."
}
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    $unexpectedOutput = Join-Path $root "$name.exe"
    if (Test-Path -LiteralPath $unexpectedOutput -PathType Leaf) {
        throw "Aut2Exe produced no EXE under dist. A $name.exe file exists in the repository root; check for an output-path override and do not use that potentially stale binary. See .build\logs\aut2exe.*.log."
    }
    throw "Aut2Exe returned success but no EXE was created: $exe. Check for a compiler error dialog and .build\logs\aut2exe.*.log."
}
if ((Get-Item -LiteralPath $exe).Length -lt 50000) { throw 'Compiled EXE is unexpectedly small.' }

# Confirm that the resulting executable contains the expected version metadata.
$info = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
if ($info.FileVersion -ne $version) {
    throw "Wrong EXE FileVersion: '$($info.FileVersion)' (expected '$version')."
}
if ($info.ProductVersion -ne $version) {
    throw "Wrong EXE ProductVersion: '$($info.ProductVersion)' (expected '$version')."
}
# Compare the embedded executable icon to the expected 32x32 fingerprint.
# This catches the generic AutoIt/window icon being used by mistake.
Add-Type -AssemblyName System.Drawing
$expectedIcon = [System.Drawing.Icon]::new($icon, [System.Drawing.Size]::new(32, 32))
$actualIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($exe)
if ($null -eq $actualIcon) { throw 'Could not extract the compiled executable icon.' }
$expectedBitmap = $expectedIcon.ToBitmap()
$actualBitmap = $actualIcon.ToBitmap()
try {
    if ($expectedBitmap.Width -ne $actualBitmap.Width -or $expectedBitmap.Height -ne $actualBitmap.Height) {
        throw 'The compiled icon size does not match the source icon.'
    }
    $expectedPixels = 0
    $actualPixels = 0
    $sharedPixels = 0
    for ($y = 0; $y -lt $expectedBitmap.Height; $y++) {
        for ($x = 0; $x -lt $expectedBitmap.Width; $x++) {
            $expectedFilled = $expectedBitmap.GetPixel($x, $y).A -ge 96
            $actualFilled = $actualBitmap.GetPixel($x, $y).A -ge 96
            if ($expectedFilled) { $expectedPixels++ }
            if ($actualFilled) { $actualPixels++ }
            if ($expectedFilled -and $actualFilled) { $sharedPixels++ }
        }
    }
    if ($expectedPixels -eq 0 -or $actualPixels -eq 0 -or
        ($sharedPixels / $expectedPixels) -lt 0.8 -or
        ($sharedPixels / $actualPixels) -lt 0.8) {
        throw 'The compiled icon differs from the selected fingerprint icon.'
    }
}
finally {
    $expectedBitmap.Dispose()
    $actualBitmap.Dispose()
    $expectedIcon.Dispose()
    $actualIcon.Dispose()
}

# Copy exactly the files intended for distribution alongside the executable.
# Both fingerprint ICO resources are embedded at compile time; no external
# ICO files, build logs, source code, or build tools belong in dist.
$licenseSource = Join-Path $root 'LICENSE'
if (-not (Test-Path -LiteralPath $licenseSource -PathType Leaf)) {
    throw 'LICENSE is required for the MIT-licensed distribution.'
}
Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination (Join-Path $dist 'README.md')
$licenseDestination = Join-Path $dist 'LICENSE'
Copy-Item -LiteralPath $licenseSource -Destination $licenseDestination
$releaseFiles = @($exe, (Join-Path $dist 'README.md'), $licenseDestination)

Write-Host "Build succeeded: $exe"
Write-Host "Distribution files are ready in: $dist"

if ($Package) {
    # Package the exact flat distribution file list, with no staging folder.
    $archive = Join-Path $dist "$name.zip"
    Compress-Archive -LiteralPath $releaseFiles -DestinationPath $archive -CompressionLevel Optimal
    Write-Host "Release archive: $archive"
}
