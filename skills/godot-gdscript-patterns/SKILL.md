---
name: godot-gdscript-patterns
description: |
  Godot 4.7 GDScript 静态类型 / @export / @onready / Signals 解耦 / Resource 数据驱动 / class_name 命名 / autoload 边界 / preload vs load。Use when the user mentions "GDScript 静态类型"、"@export"、"@onready"、"Signal 解耦"、"Resource 数据"、"class_name"、"autoload"、"类型注解"、"静态分析"。Do NOT use for UI layout (see godot-ui-best-practices) or engine subsystems (Physics/Audio/Animation have their own skills). Read-only.
last_reviewed: 2026-09-10
---

<!-- argument-hint: [pattern, e.g. 'signal', '@export', 'autoload', 'class_name', 'Resource'] -->

# Godot GDScript Patterns (4.7)

Actionable rules for GDScript: static typing, annotations, signals as decoupling, Resource as data, autoload boundaries. Deep dives in `references/<topic>.md`.

## 1. Static typing is not stylistic

`var x: int = 5` is **not** the same as `var x = 5` at runtime:

| | Untyped | Typed |
|last_reviewed: 2026-09-10
---|---|---|
| Runtime path | Variant dispatch (boxing) | Direct C-like path (no boxing) |
| Performance | ~2-4× slower per op | near-C speed |
| Static analysis | warnings only | errors at edit time |
| Memory | variant overhead | stack or direct member |

For anything beyond a demo, type aggressively. The analyzer catches type errors before runtime.

```gdscript
# Right
var hp: int = 100
var name: String = "hero"
var position: Vector2 = Vector2.ZERO
var allies: Array[Piece] = []   # typed array (Godot 4 only)

# Wrong (untyped, slower, less safe)
var hp = 100
var name = "hero"
var position = Vector2.ZERO
var allies = []
```

For variant / truly-dynamic types (e.g. JSON parsing, dictionaries with mixed types), use `Variant`:

```gdscript
var data: Variant = JSON.parse_string(raw_text)
```

## 2. `@export` for designer-tunable values

`@export` exposes a property to the Inspector, where designers (and you) can tweak it without code edits.

```gdscript
@export var speed: float = 220.0
@export_range(50.0, 800.0) var speed_clamped: float = 220.0
@export_enum("Easy", "Normal", "Hard") var difficulty: int = 1
@export var piece_data: Resource
@export var initial_position: Vector2 = Vector2(100, 100)
@export_group("Combat")
@export var attack_damage: int = 50
@export var attack_range: int = 1
```

`@export_range(min, max)` adds a slider. `@export_enum(...)` adds a dropdown. `@export_group("name")` groups properties in the inspector.

**Rule**: anything that should be tunable without code recompile gets `@export`. Gameplay numbers, art references, thresholds. Internal flags / counters don't.

## 3. `@onready` for child node caches

`@onready` resolves at `_ready()`, so `$Path` is never null when you access it later:

```gdscript
@onready var board: Board = $Board
@onready var shop_panel: PanelContainer = $HUD/ShopPanel
@onready var attack_line_pool: Array[Line2D] = $AttackLines.get_children()
```

**Why not just use `$Path` inline?** Because `$Path` calls a function each time, and if the path is wrong, the call returns null and crashes later (in a hard-to-debug location). `@onready` resolves once at `_ready`; if the path is wrong, you get an immediate error pointing at the bad line.

**Anti-pattern**: `@onready` for nodes that don't exist in the scene. Use `@export var piece_scene: PackedScene` and `instantiate()` at runtime instead.

## 4. Signals as decoupling (instead of `get_node` cross-tree access)

**Anti-pattern**: Node A reaches into Node B's tree to call its method:

```gdscript
# Node A wants to notify Node B
get_node("/root/Main/Battle/HUD/SomeLabel").text = "Score: 100"
```

**Right**: Node A emits a signal; Node B (or anyone) connects:

```gdscript
# Emitter
signal score_changed(new_score: int)
func add_score(amount: int) -> void:
    score += amount
    score_changed.emit(score)

# Listener (anywhere)
score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
    label.text = "Score: %d" % new_score
```

**Why signals**:
- Type-checked parameters (editor flags mismatches at connect time)
- Multiple listeners can react (1 emitter → N receivers)
- Decoupled: emitter doesn't know or care who listens
- Survives node reparenting / scene changes (signal connection stays)

**Type your signal parameters** for editor-time safety:

```gdscript
signal piece_killed(piece: Piece, killer: Piece)
signal hp_changed(new_hp: int, max_hp: int)
signal turn_started(turn_number: int)
```

**Connection flags**:
```gdscript
piece_killed.connect(_on_piece_killed)              # default; runs in caller
piece_killed.connect(_on_piece_killed, CONNECT_DEFERRED)   # runs at idle (safe mid-iteration)
piece_killed.connect(_on_piece_killed, CONNECT_PERSIST)   # survives scene reload
piece_killed.connect(_on_piece_killed, CONNECT_ONE_SHOT)  # auto-disconnect after one fire
```

`CONNECT_DEFERRED` is the safety net when the listener might modify the emitter's state mid-emission (e.g. modifying a list while iterating).

## 5. Resource as data (`extends Resource` + `.tres`)

For data that needs to be shared / edited / saved as a file, use a `Resource`:

```gdscript
# res://data/piece_data.gd
class_name PieceData extends Resource

@export var piece_name: String = ""
@export var max_hp: int = 100
@export var attack_damage: int = 50
@export var attack_range: int = 1
@export var color: Color = Color.WHITE
```

Save as `res://data/pieces/ply_001.tres`. Reference from a node:

```gdscript
@export var data: PieceData

func _ready() -> void:
    hp = data.max_hp
    sprite.color = data.color
```

**Why resources**:
- Inspector-editable (designers tweak without code)
- Version-controllable as `.tres` text
- Reusable across many nodes
- Type-safe: `PieceData` not `Dictionary`
- Hot-reload: edit `.tres` while game runs, see changes live

Z-2 already uses this pattern (`PieceData.tres` for each piece). Extend it for enemies, weapons, spells, buildings.

## 6. `class_name` for global script references

`class_name Foo` registers the script globally. Use it for scripts that other scripts need to reference:

```gdscript
# piece.gd
class_name Piece extends Node2D
```

Now `Piece` is a global type. Other scripts can:

```gdscript
@onready var piece: Piece = $Pieces/MyPiece
var data: PieceData
var pieces: Array[Piece] = []
```

**Anti-pattern**: `class_name` on every script. Use it for scripts that are part of the public API of your game (entities, controllers, data types). For internal helpers (e.g. a Tween factory), skip `class_name` to avoid polluting the global namespace.

**Conflict warning**: duplicate `class_name` declarations across your project cause "Script already registered" warnings. Use a project-wide prefix:

```gdscript
class_name Z2_Piece  # or just Piece; pick a convention
```

## 7. Autoload boundary (only for cross-scene infrastructure)

`Project Settings → Autoload` runs the script once at startup, accessible as a global.

**Use for**:
- Save / settings manager (survives scene change)
- Music manager (Z-2 MusicManager candidate)
- Network peer / multiplayer state
- Theme manager (if themes persist across scenes)

**Don't use for**:
- Per-scene state ("current battle", "current score")
- Anything that could be passed by reference
- Business logic that should be in a normal Node

```gdscript
# res://autoloads/save_manager.gd
extends Node

const SAVE_PATH := "user://save.json"

func save_game(data: Dictionary) -> void:
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    f.store_string(JSON.stringify(data, "\t"))

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var raw := f.get_as_text()
    return JSON.parse_string(raw) as Dictionary
```

The autoload is in the scene tree from the start. Other scripts do `SaveManager.save_game(...)` anywhere.

**Anti-pattern**: autoload as a "global var drawer" for "I'll just stash it here". This couples unrelated systems and makes testing hard.

## 8. `@warning_ignore` for justified suppressions

The static analyzer warns about:
- `unused_local_variable` (e.g. `var x := compute_x()` where `x` is set but never read)
- `unused_private_local_variable` (e.g. `var _x := ...` — note the underscore)
- `unused_parameter` (function parameter never used)
- `shadowed_variable` (local var shadows a member)
- `inferred_declaration` (`var x := 5` is untyped; use `var x: int = 5`)
- `untyped_declaration` (`: Variant` instead of a real type)
- `unsafe_method_access` (calling a method on a `Variant` type)
- `unsafe_property_access` (accessing property on `Variant`)

For justified suppressions, use `@warning_ignore`:

```gdscript
@warning_ignore("unused_parameter")
func _on_animation_finished(anim_name: StringName) -> void:
    # We don't care which animation finished; just that one did
    pass

@warning_ignore("shadowed_variable")
func complex_calculation(input: Array) -> void:
    var sum := 0  # shadows the member 'sum' on purpose
    for x in input:
        sum += x
```

**Don't blanket-ignore** — that's hiding bugs. Use suppressions per-line, with a comment explaining why.

## 9. `preload()` vs `load()`

```gdscript
# At parse time: file is read once, cached
const MyScene := preload("res://my_scene.tscn")
const MyData := preload("res://data/my_data.tres")

# At runtime: file is read each call (cached after first, but the lookup is runtime)
var scene: PackedScene = load("res://my_scene.tscn")
```

`preload()` is **statically resolved** — the path is validated at script parse time. If the file doesn't exist, the script fails to load. Use for known-fixed assets (your own scenes, your own data).

`load()` is **runtime-resolved** — the path is a string evaluated at call time. Use for:
- Mod loading (path comes from user / config file)
- Conditional loading (load `easy_mode.tres` or `hard_mode.tres` based on settings)
- Loading from a folder enumeration

```gdscript
# Right: preload your own assets
const PieceData := preload("res://data/pieces/ply_001.tres")

# Right: load mod assets at runtime
var mod_path := "res://mods/%s/piece.tres" % mod_name
var piece := load(mod_path) as PieceData
```

## 10. `Variant` boundary

Use `Variant` only at the edges:

- JSON parsing (`JSON.parse_string` returns `Variant`)
- Dictionary values (`Dictionary[String, Variant]`)
- Signal parameters that genuinely are mixed types (rare)

Inside your code, type everything:

```gdscript
# At the boundary
var raw_data: Variant = JSON.parse_string(text)

# After parsing, narrow
if typeof(raw_data) == TYPE_DICTIONARY:
    var dict: Dictionary = raw_data
    var name: String = dict.get("name", "")
    var hp: int = dict.get("hp", 0)
```

The `unsafe_method_access` and `unsafe_property_access` warnings flag this. Use them as a guide: if you see the warning, narrow the type.

## 11. Resource UID vs hardcoded paths

```gdscript
# Brittle: if you rename the file, this breaks
var scene := load("res://data/pieces/ply_001.tres")

# Robust: UID is stable across renames
var scene := load("uid://b1234abcde")
```

`uid://...` is generated when the file is first imported. The UID is stored in the file's `.import` sidecar. Right-click a file in the editor → "Copy Resource Path" or "Copy UID".

Use UIDs in `@export` properties for stable references. Plain paths are fine for one-off script code, but `@export var data: PieceData` with a UID-derived reference is more robust.

## 12. Typed dictionaries (Godot 4.4+)

```gdscript
var stats: Dictionary[String, int] = {"hp": 100, "attack": 50, "defense": 30}
var config: Dictionary[String, Variant] = {"name": "hero", "level": 5, "alive": true}
```

Typed dictionaries catch wrong-value-type access at edit time:

```gdscript
stats["hp"] = "100"   # analyzer error: expected int, got String
```

Use them when the dictionary has a known schema (save data, config, message bus). For truly dynamic data, plain `Dictionary` is fine.

## 13. Static functions (no `self`)

```gdscript
static func is_valid_position(pos: Vector2) -> bool:
    return pos.x >= 0 and pos.x < BOARD_WIDTH and pos.y >= 0 and pos.y < BOARD_HEIGHT

# Called without instance
if Board.is_valid_position(some_pos):
    ...
```

Use `static func` for utility methods that don't need instance state. They can be called from anywhere without needing a reference to an instance.

## 14. Constants vs exports vs magic numbers

| Type | Where it lives | When to change |
|---|---|---|
| `const X := 5` | in script | rarely (recompile) |
| `@export var x: int = 5` | inspector | by designer / for tuning |
| `var x: int = 5` (mutable) | runtime, instance state | not by design |

Constants for math (PI, gravity, max integer), layout (default font size, default spacing), and lookup tables. Exports for gameplay values. Mutable vars for per-instance state.

**Don't make everything `@export`** — designers drown in noise. Reserve `@export` for the 5-10 values per script that should be tunable.

## Common bug patterns

| Symptom | Root cause | Rule |
|---|---|---|
| `$Path` returns null | typo or path changed | Use `@onready`, get parse-time error |
| `null` reference in `_ready` | `$Path` called before scene tree is built | Use `@onready` (resolves at right time) |
| Static analysis noise | untyped declarations | Type everything (Rule 1) |
| Signal never fires | `emit_signal` typo, or signal connected wrong | Type signal params, IDE shows autocompletion |
| `class_name already registered` warning | duplicate `class_name` in project | search and rename |
| Resource changes don't show in game | Forgot to `@export var data: Resource` and assign in editor | Inspector-bound property |
| `load()` fails at runtime | path typo | `preload` instead (catches at parse time) |
| Mod doesn't load | used `preload` for mod path (must be runtime) | `load` with string path |

## Reference index

- `references/static-typing.md` — full guide to typing, when to use `Variant`, performance impact
- `references/signals-decoupling.md` — signals as architecture, connection patterns
- `references/resource-data-driven.md` — Resource as data, save/load, versioned assets

## Output contract

Read-only knowledge. Apply the rules when writing / fixing GDScript. Don't generate new skills; don't run scripts; don't modify files outside the active Godot project.

## Failure handling

If a GDScript bug doesn't match any rule above, the bug is either:
- Path / node tree error (Rule 3) — print `get_path()` on suspect nodes
- Signal connection error (Rule 4) — print `Object.get_signal_connection_list(signal_name)`
- Type mismatch (Rule 1) — add type annotations; warnings become errors
- Resource load error (Rule 5) — check `.import` sidecar; check `ResourceLoader.exists(path)`

If still stuck, the static analyzer is your friend: `godot --headless --check-only res://path/to/script.gd` surfaces type errors.
