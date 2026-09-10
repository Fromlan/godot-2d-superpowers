<#
.SYNOPSIS
    Run GUT tests for the current Godot project (or example-game) headlessly.

.DESCRIPTION
    Requires GUT addon installed in addons/gut/.

.PARAMETER ProjectPath
    Path to the Godot project. Default: current directory or example-game.

.PARAMETER TestPath
    Test directory (relative to project). Default: res://tests

.PARAMETER GodotPath
    Path to godot.exe. Default: "godot" (PATH).

.EXAMPLE
    .\scripts\run-tests.ps1
.EXAMPLE
    .\scripts\run-tests.ps1 -ProjectPath .\example-game
#>
param(
    [string]$ProjectPath,
    [string]$TestPath = "res://tests",
    [string]$GodotPath = "godot"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[run-tests] $Message" -ForegroundColor $Color
}

# Default project path
if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    if (Test-Path "example-game/project.godot") {
        $ProjectPath = "example-game"
    } elseif (Test-Path "project.godot") {
        $ProjectPath = "."
    } else {
        Write-Step "No project.godot found. Run init-project.ps1 first." "Red"
        exit 1
    }
}

$absPath = Resolve-Path -LiteralPath $ProjectPath
Write-Step "Project: $absPath"

# Check GUT installed
$gutPath = Join-Path $absPath "addons/gut/gut_cmdln.gd"
if (-not (Test-Path $gutPath)) {
    Write-Step "GUT not found at $gutPath" "Red"
    Write-Step "Install it from AssetLib or:" "Yellow"
    Write-Step "  cd $($absPath)\addons && git clone https://github.com/bitwes/Gut.git gut" "Yellow"
    exit 1
}

# Run
Write-Step "Running tests..."
$args = @(
    "--headless"
    "--path", $absPath
    "-s", "res://addons/gut/gut_cmdln.gd"
    "-gdir=$TestPath"
    "-gexit"
)

& $GodotPath @args
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Step "Tests passed." "Green"
} else {
    Write-Step "Tests FAILED (exit $exitCode)" "Red"
    exit $exitCode
}
