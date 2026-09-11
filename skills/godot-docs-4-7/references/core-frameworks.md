## Core Frameworks & Mental Models

<!-- ~2,000 tokens — most important knowledge first; reorder if needed. -->

### 1. Composition over inheritance (the Godot way)
Every gameplay entity is a **scene tree of nodes**, not a deep class hierarchy.
- Build behavior from small nodes (`Node2D` / `Node3D` / `Control` + specialised children) wired by signals.
- Save subtrees as `.tscn`; reuse via `PackedScene.instantiate()`.
- **Default to scenes, fall back to scripts only when flexibility requires it.**
- (Ch 1)

### 2. Signals as the universal decoupling layer
`Object.signal name(args)`; `name.emit(args)`; `node.name.connect(callable, flags)`.
- Always prefer signals over cross-node `get_node` calls.
- Use flags: `CONNECT_DEFERRED` (idle-time safety), `CONNECT_PERSIST` (saved in scene), `CONNECT_ONE_SHOT`.
- **Type your signals** (typed parameters surfacing editor-time errors).
- (Ch 4)

### 3. Action-based input
Define `"jump"`, `"move_left"`, etc. once in `Project Settings → Input Map`; bind all devices.
Read with `Input.get_vector(&"move_left", &"move_right", ...)`, `Input.is_action_just_pressed(&"jump")`.
- Never read raw `KeyEvent`s; remapping is for free if you do.
- (Ch 10)

### 4. Optional static typing in GDScript
`var x: int = 5` → typed fast path + analyzer errors at edit time. Mark `@warning_ignore(...)` per-line.
- For anything beyond a demo, type aggressively.
- (Ch 3)

### 5. `@export` for designers, `@onready` for caches
- `@export` exposes a property to the Inspector (variants: `@export_range`, `@export_enum`, `@export_resource("Type")`).
- `@onready var x := $Path` resolves at `_ready()` so `$Path` is never null.
- (Ch 3)

### 6. Forward-decide the renderer
Lock renderer at project creation (Forward+ / Mobile / Compatibility). Switching later is expensive.
- Forward+ — desktop, full effects (SDFGI, volumetric fog).
- Mobile — phones, lower overhead.
- Compatibility — OpenGL ES 3.0 fallback.
- (Ch 7, 9)

### 7. Body decision matrix (2D and 3D)
| Need | Body |
|---|---|
| Player, NPC, boss (you drive motion) | `CharacterBody2D / 3D` + `move_and_slide` |
| Crate, ragdoll, debris (engine simulates) | `RigidBody2D / 3D` |
| Trigger / pickup / zone (overlap only) | `Area2D / 3D` |
| Static level geometry | `StaticBody2D / 3D` |

- Use collision **layer** (what I am) and **mask** (what I collide with) — 32-bit bitfields, much cleaner than `if`-checks.
- (Ch 6, 7)

### 8. High-level multiplayer: `@rpc`, `MultiplayerSpawner`, `MultiplayerSynchronizer`
- `@rpc("any_peer", "call_local", "reliable") func chat(msg: String): …` — annotate any function as remotely callable; modes include `"authority"`, `"call_local"`, transports `"reliable"`/`"unreliable"`.
- `MultiplayerSpawner` replicates scene instantiation from authority to clients.
- `MultiplayerSynchronizer` + `SceneReplicationConfig` replicate properties by mode (always / on_change / initial).
- (Ch 11)

### 9. Resources as data, Nodes as logic
Anything reusable (textures, sounds, materials, weapons) is a `Resource` saved as `.tres`; entities (`Node`s) carry behavior and reference resources.
- Use `@export_resource("Type")` to bind resource subtypes.
- Stable handles: `uid://b1234…` survive renames.
- (Ch 4, 5)

### 10. Persistence in `user://` (not `res://`)
`FileAccess.open("user://save.json", FileAccess.WRITE).store_string(JSON.stringify(d))`.
- `user://` is per-user and writable; `res://` is read-only after export.
- Use `JSON.stringify(d, "\t")` for portable, version-tagged saves.
- (Ch 11)

### 11. Tween for any one-shot visual interpolation
`var t := create_tween(); t.tween_property(node, "scale", Vector2.ONE * 1.1, 0.15)` — also `tween_callback(node.queue_free)`.
- Use over `_process` for any UI / camera / shader pulse.
- (Ch 8, 10)

### 12. WorldEnvironment & GI choices
- One `WorldEnvironment` per scene for fog / sky / SSR / glow.
- Pick per-project: `VoxelGI` (real-time), `LightmapGI` (baked), `SDFGI` (Forward+ only).
- `mesh.gi_mode` must match: `STATIC`, `DYNAMIC`, `LIGHTMAPPED`, `NONE`.
- (Ch 9)

### 13. Editor extensibility via `EditorPlugin`
Place in `addons/<name>/`:
```
[plugin]
name="My Plugin"
script="plugin.gd"
```
```gdscript
@tool extends EditorPlugin
func _enter_tree() -> void: add_custom_type("MyTool","Node",preload("tool.gd"),preload("icon.svg"))
func _exit_tree() -> void: remove_custom_type("MyTool")
```
Mark scripts `@tool` to run in the editor. (Ch 12)

### 14. Autoloads reserved for infrastructure
Use `Project Settings → Autoload` for **truly cross-cutting state**: save manager, audio bus, networking peer. Do **not** autoload everything. (Ch 5)

### 15. CI / Headless release pipeline
`godot --headless --path proj --export-pack "Linux/Server" build/server.x86_64` covers >90% of build cases. (Ch 12)

---

