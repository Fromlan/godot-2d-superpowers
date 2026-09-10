<#
.SYNOPSIS
    Headless smoke test: load the main scene and quit after N seconds.

.DESCRIPTION
    Use this as a quick "does it even run?" check, especially in CI or before commit.

.PARAMETER ProjectPath
    Path to the Godot project. Default: example-game.

.PARAMETER Scene
    Scene to load. Default: res://scenes/main.tscn

.PARAMETER Seconds
    Run for N seconds then auto-quit. Default: 10.

.PARAMETER GodotPath
    Path to godot.exe. Default: "godot"

.EXAMPLE
    .\scripts\headless-smoke.ps1 -Seconds 30
#>
param(
    [string]$ProjectPath = "example-game",
    [string]$Scene = "res://scenes/main.tscn",
    [int]$Seconds = 10,
    [string]$GodotPath = "godot"
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path $ProjectPath)) {
    Write-Host "[headless-smoke] Project path not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

Write-Host "[headless-smoke] Project: $ProjectPath" -ForegroundColor Cyan
Write-Host "[headless-smoke] Scene:   $Scene" -ForegroundColor Cyan
Write-Host "[headless-smoke] Seconds: $Seconds" -ForegroundColor Cyan

& $GodotPath --headless --path $ProjectPath --quit-after $Seconds $Scene 2>&1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "[headless-smoke] OK (no fatal error)" -ForegroundColor Green
} else {
    Write-Host "[headless-smoke] FAILED (exit $exitCode)" -ForegroundColor Red
    exit $exitCode
}
