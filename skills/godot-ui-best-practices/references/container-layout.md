# Container Layout (deep dive)

Reference for SKILL.md §1 + §2.

## Container types

| Type | Use |
|-------|-----|
| VBoxContainer | vertical flow |
| HBoxContainer | horizontal flow |
| GridContainer | fixed N×M (e.g. inventory grid) |
| MarginContainer | uniform padding inside a parent |
| CenterContainer | single child, centered |
| PanelContainer | auto-sized panel around child with content_margin_* |
| ScrollContainer | auto-scrollable area |
| AspectRatioContainer | maintain aspect |
| SplitContainer | draggable splitter |

## size_flags_*

| Constant | Value | Meaning |
|----------|-------|---------|
| SIZE_SHRINK_END | 0 | shrink to fit; default |
| SIZE_FILL | 1 | fill available space |
| SIZE_EXPAND | 2 | parent grows the slot |
| SIZE_EXPAND_FILL | 3 | both |
| SIZE_SHRINK_CENTER | 4 | center, shrink |
| SIZE_SHRINK_BEGIN | 8 | align to start |

size_flags_horizontal and size_flags_vertical are separate.

## Common patterns

### HUD top bar (full width, fixed height)

```gdscript
@onready var top_bar: PanelContainer = $HUD/TopBar
top_bar.anchor_left = 0
top_bar.anchor_right = 1
top_bar.anchor_top = 0
top_bar.anchor_bottom = 0
top_bar.offset_right = 0
top_bar.offset_bottom = 64
```

### HP bar (fill horizontal, shrink end vertical)

```gdscript
@onready var hp_bar: ProgressBar = $HUD/HP
hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
hp_bar.size_flags_vertical = Control.SIZE_FILL
```

### Popup (centered, with margins)

```
Popup (CenterContainer)
  └─ MarginContainer (margin: 16)
      └─ VBoxContainer (separation: 8)
          ├─ Label (title)
          ├─ HBoxContainer (buttons)
```

## Pitfall: PanelContainer + VBoxContainer

PanelContainer sizes to its child. If the child VBox has size_flags_vertical = SIZE_FILL, it tries to fill — PanelContainer then expands to fit, growing past its offset_bottom and overflowing into adjacent UI.

Fix: inner VBoxContainer.size_flags_vertical = 0 (SHRINK_END).

## Pitfall: Manual position

Never set position on children of a Container — the Container will overwrite it. Use size_flags_* and offset_*.

## Theme integration

```gdscript
$Root.theme = preload("res://theme.tres")
```

Themes style all Button / Label etc. automatically. Inline theme_override_* only for one-off overrides.
