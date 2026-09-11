# Changelog

All notable changes to this example game are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning follows [SemVer](https://semver.org/).

## [0.1.0] - 2026-09-11

### Added
- Sample 2D platformer demonstrating godot-2d-superpowers workflow.
- Player controller (CharacterBody2D with @export, @onready, signals, pure-function extraction).
- Coin pickup (Area2D), patrolling enemy (CharacterBody2D), HUD (CanvasLayer).
- GameManager autoload singleton.
- GUT tests for logic layer:
  - `tests/test_damage_calc.gd` (RED-GREEN-REFACTOR TDD for DamageCalc).
  - `tests/test_player_physics.gd` (typed PlayerMotionOutput pure function).
- `assets/sprites/` SVG placeholders.
- Project uses UID references (Godot 4.4+) for scene/script cross-references.

### Notes
- This is the initial template. When copying to your own project:
  1. Rename `class_name DamageCalc` to `<YourGame>Damage` (see README "Renaming class_name").
  2. Update `project.godot` `config/name` and autoload path.
  3. Replace placeholder SVGs with your art (see `asset-pipeline` skill).
