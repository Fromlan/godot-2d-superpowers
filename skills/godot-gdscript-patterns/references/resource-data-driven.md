# Resource as Data (deep dive)

Reference for SKILL.md §5 + §9 + §11.

## Why Resource, not Dictionary

| | Dictionary | Resource |
|--|------------|----------|
| Type safety | none | typed (analyzer catches errors) |
| Editor binding | no | yes (@export var x: MyResource) |
| Inspector tweakable | no | yes |
| Save / load | JSON.stringify | ResourceSaver.save / @export |
| IDE navigation | no (string keys) | yes (click to definition) |
| Runtime cost | hash lookup | direct member access |

For anything that has a known shape, use a Resource subclass.

## Subclass template

```gdscript
# res://data/piece_data.gd
class_name PieceData extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var cost: int = 1
@export var base_hp: int = 100
@export var base_attack: int = 50
@export var icon: Texture2D
@export var tier: int = 1
@export_group("Effects")
@export var on_spawn_effect: PackedScene
@export var on_kill_effect: PackedScene
```

Save instances as .tres:

```ini
; res://data/pieces/ry_001.tres
[gd_resource type="Resource" script_class="PieceData" load_steps=2 format=3]
[ext_resource type="Script" path="res://data/piece_data.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"knight"
display_name = "Knight"
cost = 2
base_hp = 150
base_attack = 40
icon = ExtResource("...")
```

## Load + use

```gdscript
# Preload (parse-time, catches missing file)
const KNIGHT := preload("res://data/pieces/knight.tres")

# Or by ID (runtime)
var piece: PieceData = load("res://data/pieces/%s.tres" % id)

# Or by UID (most robust)
var piece: PieceData = load("uid://b1234abcde")
```

## Resource as level data

See level-data-flow skill for full pattern (LevelLayout subclass).

## @export_resource (typed export)

```gdscript
@export_resource("PieceData") var piece_data: Resource
```

The Inspector will only let you drag in PieceData subclasses.

## UID vs path

```gdscript
# Brittle (path-based; rename breaks)
var p := load("res://data/knight.tres")

# Robust (UID survives rename)
var p := load("uid://b1234abcde")
```

UID is in the file's .import sidecar. Right-click in editor → "Copy UID".

## Versioning

For save data, use @export + a schema_version: int field. On load, branch on version to migrate.

```gdscript
@export var schema_version: int = 1
```
