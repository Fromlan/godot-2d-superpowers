<#
.SYNOPSIS
    Export the Godot project to a build artifact for a target platform.

.DESCRIPTION
    Requires the corresponding export preset to be configured in the Godot editor
    (or in export_presets.cfg).

.PARAMETER ProjectPath
    Path to the Godot project. Default: example-game.

.PARAMETER Preset
    Export preset name. Common values: "Windows Desktop", "Web", "Linux/X11", "macOS".

.PARAMETER Output
    Output file path. Default: build/<platform>/yourgame.<ext>

.PARAMETER GodotPath
    Path to godot.exe. Default: "godot"

.EXAMPLE
    .\scripts\export-build.ps1 -Preset "Windows Desktop" -Output build\windows\game.exe
.EXAMPLE
    .\scripts\export-build.ps1 -Preset "Web" -Output build\web\index.html
#>
param(
    [string]$ProjectPath = "example-game",
    [string]$Preset = "Windows Desktop",
    [string]$Output = "build/windows/game.exe",
    [string]$GodotPath = "godot"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProjectPath)) {
    Write-Host "[export-build] Project path not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

$outputDir = Split-Path -Parent $Output
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "[export-build] Project: $ProjectPath" -ForegroundColor Cyan
Write-Host "[export-build] Preset:  $Preset" -ForegroundColor Cyan
Write-Host "[export-build] Output:  $Output" -ForegroundColor Cyan

& $GodotPath --headless --path $ProjectPath --export-release $Preset $Output 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "[export-build] OK" -ForegroundColor Green
} else {
    Write-Host "[export-build] FAILED (exit $exitCode)" -ForegroundColor Red
    exit $exitCode
}
