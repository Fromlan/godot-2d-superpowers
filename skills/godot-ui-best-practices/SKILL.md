---
name: godot-ui-best-practices
description: |
  Godot 4.7 UI / HUD / CanvasLayer / Control 实战最佳实践 + 常见踩坑。Use when the user mentions "Godot UI"、"HUD"、"Control"、"CanvasLayer"、"godot 拖拽"、"godot 按钮"、"godot 布局"、"mouse_filter"、"Theme"、or asks to build / fix UI scenes, HUD, menus, drag-and-drop. Triggers on "UI 优化"、"按钮没响应"、"点击没反应"、"拖不动"、"HUD 适配视口". Do NOT use for pure GDScript logic, non-UI scenes, or non-Godot engines.
last_reviewed: 2026-09-10
---

<!-- argument-hint: [rule number or symptom, e.g. '3', 'mouse_filter', 'drag 不触发'] -->

# Godot UI Best Practices (4.7)

Actionable rules for building Godot 4 Control / HUD UI. Each rule states the failure mode, the fix, and a one-liner code example. Deep dives live in `references/<topic>.md`.

## 1. Container drives layout, not manual `position`

Every layout problem starts with the same mistake: child nodes with hardcoded `position` inside a `Container`. Containers are the engine; let them work.

| Bad | Good |
|last_reviewed: 2026-09-10
---|---|
| 5 children with `position = Vector2(0, 60 * i)` inside a node | `VBoxContainer` with `theme_override_constants/separation = 8` |
| 3 children with manual x/y inside a `Node2D` | `HBoxContainer` (or `GridContainer` for fixed columns) |
| 4 corners of a popup manually placed | `MarginContainer` + `VBoxContainer` nested |

`Container` types and when to use:
- `VBoxContainer` / `HBoxContainer` — vertical/horizontal flow
- `GridContainer` — fixed N×M grid
- `MarginContainer` — uniform padding inside a parent
- `CenterContainer` — single child centered
- `PanelContainer` — auto-sizes to child + `content_margin_*` (see Rule 9)
- `ScrollContainer` — auto scrollable area

**Why**: manual `position` breaks the moment you change a font, add a child, or resize the window. Container rebuilds correctly.

## 2. `size_flags_*` for child fill/shrink behavior

A `Container` lays out children; `size_flags_*` on each child tells it how. Defaults are wrong for HUD bars, headers, and dynamic content.

```gdscript
# Expand fill horizontal + shrink end vertical — header bar pattern
header.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # 1
header.size_flags_vertical   = Control.SIZE_SHRINK_END   # 0
```

Values: `0=SHRINK_END`, `1=FILL`, `2=EXPAND`, `3=EXPAND_FILL`. The combination of `EXPAND` (parent grows the slot) + `FILL` (child fills the slot) is the common "stretchy" case.

**Pitfall**: `PanelContainer` with a `VBoxContainer` child. If the `VBoxContainer` has default `size_flags_vertical = SIZE_FILL` (1), it tries to fill the parent. The `PanelContainer` then expands to fit the `VBoxContainer`. The result: panel grows past its `offset_bottom` and overflows into adjacent UI. **Fix**: set the inner `VBoxContainer.size_flags_vertical = 0` (SHRINK_END) so the panel uses its offset rect.

## 3. `mouse_filter` is the #1 cause of "click doesn't fire"

Every `Control` has `mouse_filter`:
- `STOP = 0` (default) — eats the event, doesn't pass to siblings or `_unhandled_input`
- `PASS = 1` — sees the event, passes it to siblings + `_unhandled_input`
- `IGNORE = 2` — invisible to mouse, event goes through completely

The **default STOP** means a decorative `Label` next to a game object (a piece, a card, a 3D prop) silently eats clicks before they reach the parent's `_unhandled_input`. This is the most common "drag doesn't work" cause.

```gdscript
# 装饰性 Control 必须显式设 IGNORE, 否则吞掉点击
label.mouse_filter   = Control.MOUSE_FILTER_IGNORE   # 2
hp_bar.mouse_filter  = Control.MOUSE_FILTER_IGNORE   # 2

# 真正要点击的 Button 保持 STOP
button.mouse_filter  = Control.MOUSE_FILTER_STOP     # 0
```

**Diagnose**: in `_unhandled_input` first line, `print(event.position, " ", event.pressed)`. If nothing prints on click, a `Control` above the game object is eating it. Set the suspect's `mouse_filter = 2`.

## 4. Click event chain: `_input` → `_gui_input` → `_unhandled_input`

For UI buttons, **always** connect to `Button.pressed` signal. Don't poll for clicks in `_unhandled_input` to drive button actions.

```gdscript
# Right — signal-driven
shop_buy_btn.pressed.connect(_on_shop_buy)

# Wrong — polling for a Button click
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if Rect2(shop_buy_btn.global_position, shop_buy_btn.size).has_point(event.position):
            _on_shop_buy()  # duplicates Button's own logic, breaks with input devices
```

Use `_unhandled_input` only for **game actions that aren't buttons**: drag, hotkey for game command, camera pan, etc. Even then, the actual game object hit-test is your job — `Container` doesn't help.

## 5. `_input` vs `_unhandled_input` vs `_gui_input`

| Hook | When it fires | Use for |
|---|---|---|
| `_input` | every event, before GUI processing | input recording / replay, debug overlays |
| `_unhandled_input` | only events no `Control` consumed | game logic (drag, world click) |
| `_gui_input` | only on hovered `Control` | per-control custom behavior (drag inside a `Panel`) |

Default game logic → `_unhandled_input`. Custom widget behavior → `_gui_input` on that widget.

## 6. Tween for every one-shot visual interpolation

Direct property assignment for "drag start highlight" or "menu open fade" is a no-op feel. Use `create_tween()`:

```gdscript
# Drag start: 80ms fade to bright + scale 1.15x
var t := create_tween()
t.set_parallel(true)
t.tween_property(piece, "modulate", Color(1.4, 1.4, 1.0), 0.08)
t.tween_property(piece, "scale",    Vector2.ONE * 1.15, 0.08)

# Drag end: reverse
t = create_tween()
t.tween_property(piece, "modulate", Color.WHITE, 0.08)
t.tween_property(piece, "scale",    Vector2.ONE, 0.08)
```

Tweens pause on `SceneTree.paused = true` automatically — usually what you want. Cancel before `queue_free` if the target is an autoload-managed tween.

## 7. Action-based input, not raw `KeyEvent`

Define actions in **Project Settings → Input Map** ("ui_select", "drag_piece", "pause"). Bind keys + gamepad. Read with `Input.is_action_pressed(&"drag_piece")`. Polling raw `KEY_SPACE` blocks rebinding and gamepad forever.

For mouse-only games (most strategy), `_unhandled_input` with `InputEventMouseButton` is fine, but **define the action anyway** so rebinding is on the table.

## 8. CanvasLayer for HUD, not sibling Node2D

HUD on the same layer as game objects means:
- Drag-to-camera breaks HUD positions
- Camera zoom scales the HUD too
- Click priority is ambiguous (HUD on top? game on top?)

Put HUD under a `CanvasLayer`:

```
Battle (Node2D)
├── Board (Node2D)        ← game world
├── Pieces (Node2D)       ← draggable game objects
└── HUD (CanvasLayer)     ← always on top, unaffected by camera
    ├── TopBar
    ├── ShopPanel
    └── BottomBar
```

`CanvasLayer.layer` controls stacking order across layers. `layer=1` is above default.

## 9. PanelContainer + StyleBox: respect `content_margin_*`

When you theme a `PanelContainer` with a `StyleBoxFlat` and set `content_margin_left/right/top/bottom`, the panel auto-sizes around the child + margins. Don't also set `offset_*` to fight the margins.

```ini
[sub_resource type="StyleBoxFlat" id="panel"]
bg_color = Color(0.1, 0.1, 0.1, 0.9)
content_margin_left = 10.0
content_margin_top = 10.0
content_margin_right = 10.0
content_margin_bottom = 10.0
```

`Panel` (no Container suffix) does NOT auto-size. Use `PanelContainer` for HUD panels.

## 10. Viewport size must match design or content overflows

If your `.tscn` lays out for 1152×720 but `project.godot` doesn't pin viewport size, Godot uses its default (1152×648). Buttons in `y=672-704` will be cut off the bottom, and `get_viewport_rect().size` returns the actual size, not your design size.

**Always set explicitly**:
```ini
[display]
window/size/viewport_width=1152
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

Verify on every layout change: print `get_viewport_rect().size` in `_ready()`.

## 11. Anchor + offset, not absolute position, for resize-friendly UI

Top-level HUD nodes that should "stick" to an edge:
- Top bar: `anchor_left=0, anchor_right=1, anchor_top=0, offset_right=0` (full width, top)
- Bottom bar: `anchor_left=0, anchor_right=1, anchor_bottom=1, offset_top=-X` (full width, X px from bottom)
- Side panel: `anchor_left=1, anchor_right=1, anchor_top=0, anchor_bottom=1` (right edge, full height)

Without anchors, resize leaves the panel stranded in the middle of the screen.

For fixed-size game windows (e.g. 1152×720 Steam target), anchors are optional. For browser / mobile / responsive, anchors are required.

## 12. Hit-test: `hit_radius` should be larger than visual

Game objects you click on (pieces, cards, units) should expose a `hit_radius` that is **larger than the visible sprite**. 9×9 board with 56px cells and 22×9 visible piece → `hit_radius=36` is comfortable, `hit_radius=28` is too tight.

The visible bounds define what the user *sees*; the hit radius defines what the user *can click*. They are not the same number.

## 13. Don't manually position labels inside `Container`

| Bad | Good |
|---|---|
| 5 `Label` children with `position = Vector2(0, 32 * i)` | `VBoxContainer` with default separation |
| `Label` next to `Button` with manual `x` offset | `HBoxContainer` with `add_child(label)` then `add_child(button)` |

The `Container` is auto-aligning, font-size-adaptive, and themeable. Manual positioning is the enemy of every future font / theme change.

## 14. Resource-based theming, not inline colors

A `Theme` resource (`res://theme.tres`) is one file that styles every `Button` / `Label` in the project. Inline `theme_override_colors/font_color = Color(...)` per button is a maintenance trap.

```gdscript
# Project theme: a single .tres file with styleboxes, fonts, colors
# Apply at the project root or per-scene root:
$Root.theme = preload("res://theme.tres")
```

For one-off overrides (e.g. error text red), use `theme_override_*` — but keep them minimal.

## 15. `@export` for designer-tunable values, `@onready` for child caches

```gdscript
@export_range(50.0, 800.0) var piece_drag_speed: float = 220.0
@export var piece_scene: PackedScene

@onready var board: Board = $Board
@onready var shop_panel: PanelContainer = $HUD/ShopPanel
```

`@onready var` resolves at `_ready()` so `$Path` is never null. `@export` exposes to Inspector for designer tuning without recompile.

## 16. The four minimum diagnostics

When UI breaks, in this order:

1. `print(get_viewport_rect().size)` in `_ready()` — confirm viewport size matches design
2. `print(node.global_position, node.size, node.mouse_filter)` for every overlapping `Control` — find the click-eater
3. In `_unhandled_input` first line: `print(event.position, " ", event.pressed)` — confirm event reached the parent
4. `print(piece.position, piece.hit_radius, "d=", mouse.distance_to(piece.position))` — confirm hit-test math

These four prints solve 90% of "UI doesn't work" debugging.

---

## Common bug patterns

| Symptom | Root cause | Rule |
|---|---|---|
| Button click does nothing | `_input` handler consumed it | 4 |
| Drag works on object, not on its label | Label `mouse_filter=STOP` | 3 |
| Panel grows past its `offset_bottom` | Inner `VBox` has `SIZE_FILL` | 2 |
| HUD cut off at bottom | Viewport smaller than design | 10 |
| Panel in wrong place after resize | Used absolute `position`, not anchors | 11 |
| Tween freezes when scene changes | Autoload-managed tween; cancel before `queue_free` | 6 |
| Click on game object behind HUD never fires | HUD `Control` is on top in `CanvasLayer` | 3 + 8 |

## Reference index

For deep dives:

- `references/container-layout.md` — full container / size_flags reference with diagrams
- `references/mouse-and-click.md` — `_input` chain, drag patterns, `mouse_filter` deep dive
- `references/visual-feedback.md` — Tween patterns, modulate, custom cursor
- `references/responsive-layout.md` — anchors, stretch modes, multi-resolution

## Output contract

This skill is read-only knowledge. Apply its rules when writing / fixing Godot UI. Don't generate new skills; don't run scripts; don't modify files outside the active Godot project.

## Failure handling

If a UI bug doesn't match any rule above, the bug is either:
- viewport size mismatch (Rule 10) — print and verify
- a non-`Control` parent issue (e.g. `Node2D` is the parent, drag is a custom hit_radius — see `references/mouse-and-click.md`)
- a script bug in the handler — print inside the handler

If still stuck, fall back to the four diagnostics (Rule 16) in order.
