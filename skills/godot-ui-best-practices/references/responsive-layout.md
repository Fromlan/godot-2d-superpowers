# Responsive Layout (deep dive)

Reference for SKILL.md §10 + §11.

## Viewport stretch

```ini
; project.godot
[display]
window/size/viewport_width=1152
window/size/viewport_height=720
window/stretch/mode = "canvas_items"
window/stretch/aspect = "expand"
```

Modes: disabled, keep, keep_width, keep_height, expand.

| Mode | Behavior |
|------|----------|
| disabled | fixed viewport size; no scaling |
| keep | uniform scale to fit; black bars on aspect mismatch |
| keep_width | scale to fit width; may show more vertically |
| keep_height | scale to fit height; may show more horizontally |
| expand | stretch non-uniformly to fill |

keep + 16:9 design resolution is the most common choice.

## Anchor + offset (instead of absolute position)

For HUD that sticks to edges:

```gdscript
# Top bar: full width, 64 px tall
top_bar.anchor_left = 0.0
top_bar.anchor_top = 0.0
top_bar.anchor_right = 1.0
top_bar.anchor_bottom = 0.0
top_bar.offset_right = 0
top_bar.offset_bottom = 64

# Bottom bar: full width, 80 px from bottom
bottom_bar.anchor_left = 0.0
bottom_bar.anchor_top = 1.0
bottom_bar.anchor_right = 1.0
bottom_bar.anchor_bottom = 1.0
bottom_bar.offset_top = -80

# Side panel: right edge, full height
side_panel.anchor_left = 1.0
side_panel.anchor_top = 0.0
side_panel.anchor_right = 1.0
side_panel.anchor_bottom = 1.0
side_panel.offset_left = -200
```

Without anchors, the panel stays where you placed it and looks wrong after window resize.

## viewport.size vs design size

get_viewport_rect().size returns the actual viewport size in pixels. If your design is 1152×720 and the window is 1280×720, viewport is 1280×720. UI should respond accordingly.

## Mobile touch

For touch, use InputEventScreenTouch / InputEventScreenDrag (or just define touch action in InputMap).

```ini
[input]
tap={
"events": [
Object(InputEventMouseButton,"button_index":="1"),
Object(InputEventScreenTouch,"index":="-1")
]
}
```

## Multi-resolution support

| Target | Approach |
|--------|----------|
| Steam fixed-size 1152x720 | no anchors needed; set viewport explicitly |
| Web browser | anchors + responsive layout |
| Mobile | anchors + different baseline size per device class |

## Common pitfalls

| Symptom | Cause | Fix |
|---------|-------|-----|
| HUD cut off at bottom | viewport smaller than design | stretch mode expand or resize design |
| UI in wrong place after resize | absolute position | use anchors |
| Different aspect ratios show different content | design assumes one aspect | design for the widest reasonable aspect |
| get_viewport_rect().size is wrong | querying in _init before viewport exists | query in _ready or later |
