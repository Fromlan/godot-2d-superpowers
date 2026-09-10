<#
.SYNOPSIS
    Initialize a new 2D Godot project structure following godot-2d-superpowers conventions.

.DESCRIPTION
    Creates the standard directory layout:
        scenes/, scripts/, assets/{sprites,sounds,fonts,animations}/,
        resources/levels/, tests/, addons/
    Plus a minimal project.godot and .gitignore.

.PARAMETER Path
    Target directory. Default: current directory.

.PARAMETER Name
    Project name (used in project.godot). Default: "My 2D Game".

.PARAMETER GodotPath
    Path to godot.exe. Default: "godot" (relies on PATH).

.EXAMPLE
    .\scripts\init-project.ps1 -Path C:\projects\my-game -Name "Pixel Quest"
#>
param(
    [string]$Path = ".",
    [string]$Name = "My 2D Game",
    [string]$GodotPath = "godot"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[init-project] $Message" -ForegroundColor Cyan
}

# Resolve absolute path
$ProjectRoot = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
if (-not $ProjectRoot) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    $ProjectRoot = Resolve-Path -LiteralPath $Path
}
Write-Step "Initializing at: $ProjectRoot"

# Create directory layout
$dirs = @(
    "scenes",
    "scripts",
    "assets/sprites",
    "assets/sounds",
    "assets/fonts",
    "assets/animations",
    "resources/levels",
    "tests",
    "addons",
    "prototype"
)
foreach ($d in $dirs) {
    $full = Join-Path $ProjectRoot $d
    if (-not (Test-Path $full)) {
        New-Item -ItemType Directory -Path $full -Force | Out-Null
        Write-Step "  created $d"
    }
}

# .gitignore
$gitignore = @"
# Godot
.godot/
.import/

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/

# Build
build/
exports/

# Local
*.local
"@
Set-Content -LiteralPath (Join-Path $ProjectRoot ".gitignore") -Value $gitignore
Write-Step "  wrote .gitignore"

# project.godot
$projectGodot = @"
; Engine configuration file.
config_version=5

[application]

config/name="$Name"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[layer_names]

2d_physics/layer_1="player"
2d_physics/layer_2="enemy"
2d_physics/layer_3="world"
2d_physics/layer_4="pickup"

[physics]

2d/default_gravity=980.0
"@
Set-Content -LiteralPath (Join-Path $ProjectRoot "project.godot") -Value $projectGodot
Write-Step "  wrote project.godot"

# ATTRIBUTION.md
$attribution = @"
# Asset Attribution

List each asset's source + license here. Format:

- `path/to/asset.png`: author / license / source_url
"@
Set-Content -LiteralPath (Join-Path $ProjectRoot "assets/ATTRIBUTION.md") -Value $attribution
Write-Step "  wrote assets/ATTRIBUTION.md"

Write-Step ""
Write-Step "Done. Next steps:" -ForegroundColor Green
Write-Step "  1. Open the project in Godot 4.7"
Write-Step "  2. Install GUT addon (see example-game/README.md)"
Write-Step "  3. Start with skill: game-brainstorming or game-writing-plans"
