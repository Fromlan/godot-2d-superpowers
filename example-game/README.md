# Example 2D Platformer (godot-2d-superpowers)

> 30-minute runnable 2D platformer demonstrating the workflow skills.
> Use this as a template: copy and replace mechanics for your own game.

## What's in here

- **Player**: CharacterBody2D, move + jump + coyote time + jump buffer (TDD pure function)
- **Coin**: Area2D collectible
- **Enemy**: CharacterBody2D patrolling, deals damage
- **HUD**: CanvasLayer with HP / Score / Restart
- **GameManager**: autoloaded singleton
- **Tests**: GUT tests for damage calculation + player motion pure function

## How to run

1. Open this directory in Godot 4.7
2. Press F5 (or click Play)
3. Use A/D (or arrow keys) to move, Space to jump
4. Collect coins, avoid the enemy

If keyboard doesn't work, check InputMap in Project Settings (the project.godot has defaults: A, D, Space).

## How to test

### From Godot editor

1. Install GUT addon (see below)
2. Open GUT panel at bottom
3. Click "Run All"

### From command line (Windows PowerShell)

```powershell
# From godot-2d-superpowers root
.\scripts\run-tests.ps1
```

This runs GUT headless on the example game's tests.

## Installing GUT

This template does NOT bundle GUT to keep the repo small. Install it once:

1. In Godot, go to AssetLib (top menu → Asset → AssetLib)
2. Search "GUT" (Godot Unit Test) by bitwes
3. Download and install to `example-game/addons/gut/`
4. Enable the plugin: Project → Project Settings → Plugins → enable "GUT"

Or via git:

```bash
cd example-game/addons
git clone https://github.com/bitwes/Gut.git gut
```

Then enable in project.godot or via Plugins panel.

## What to do with this example

1. **Read it top-to-bottom**: scripts are heavily commented, walk through player.gd first
2. **Tweak numbers**: open player.tscn, change `max_speed` or `jump_velocity` in inspector, re-run
3. **Add a level**: see `skill:level-data-flow` — add a `LevelLayout` resource + level_builder.gd
4. **Add art**: drop sprites in `assets/sprites/`, follow `skill:asset-pipeline`
5. **Add a feature**: walk through `game-brainstorming` → `gdd-author` → `game-writing-plans` → `godot-coding-2d`

## Skill mapping

| This file | Skill that produced it |
|-----------|------------------------|
| `scripts/damage_calc.gd` | `godot-coding-2d` (logic layer, TDD) |
| `scripts/player.gd` (compute_motion) | `godot-coding-2d` (pure function extraction) |
| `tests/test_damage_calc.gd` | `godot-coding-2d` (TDD RED-GREEN-REFACTOR) |
| `scripts/game_manager.gd` (autoload) | `godot-gdscript-patterns` (autoload boundary) |
| `scenes/*.tscn` (uid://) | `godot-docs-4-7` (4.4+ uid system) |
| `assets/sprites/icon.svg` | `asset-pipeline` (programmatic placeholder) |
| `project.godot` (layer_names) | `godot-2d-physics` (collision layers) |



## Renaming class_name before forking into your own project

The example declares two `class_name` values: `DamageCalc` (in `scripts/damage_calc.gd`) and
`PlayerMotionOutput` (in `scripts/player_motion_output.gd`).

If you copy this project into another Godot project that also has these names, you'll get
`class_name already registered` warnings. Rename them to project-scoped names:

1. `DamageCalc` → `<YourGame>Damage` (or similar; the convention is one namespace per project).
2. `PlayerMotionOutput` → `<YourGame>MotionOutput`.
3. Update all references:
   - `scripts/player.gd` uses `PlayerMotionOutput.new()` and `-> PlayerMotionOutput` return type.
   - `tests/test_damage_calc.gd` calls `DamageCalc.compute(...)`.

A safe mass-rename pattern (PowerShell):

```powershell
Get-ChildItem -Path . -Recurse -Include *.gd | ForEach-Object {
  (Get-Content $_.FullName) -replace 'DamageCalc', 'MyGameDamage' | Set-Content -Path $_.FullName -Encoding UTF8
}
```

Then verify no leftover references:

```powershell
Get-ChildItem -Path . -Recurse -Include *.gd | Select-String -Pattern 'DamageCalc'
# Should return no matches.
```

## License

MIT. Sprite placeholder is hand-drawn SVG, original.
