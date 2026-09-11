# Audio Bus Layout (deep dive)

Reference for SKILL.md §2.

## Standard starter (3 buses under Master)

```
Master
├── Music     (BGM; lowered when SFX peak)
├── SFX       (combat, footsteps, impacts)
└── UI        (clicks, notifications; never lowered)
```

## Adding effects

Each bus has an effect chain (insert). Order matters — first effect = first signal path.

Common chain:
```
Master bus:
  Compressor (limit overall peak)
  Limiter (prevent clipping)

Music bus:
  EQ (warm low end)
  Compressor (smooth dynamics)
  Reverb (send, optional)

SFX bus:
  PitchShift (if you want global pitch)
  Compressor (glue)

UI bus:
  (none usually)
```

## Set bus on a player

```gdscript
sfx_player.bus = "SFX"
music_player.bus = "Music"
ui_player.bus = "UI"
```

## Default bus layout file

res://default_bus_layout.tres (auto-generated when you edit buses in editor).

## duck() implementation

```gdscript
func duck_music(target_db := -12.0, time := 0.2) -> void:
    var idx := AudioServer.get_bus_index("Music")
    var current_db := AudioServer.get_bus_volume_db(idx)
    var t := create_tween()
    t.tween_method(
        func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v),
        current_db, target_db, time
    )
```

target_db = -12 is a common perceptual reduction without making music inaudible.

## Volume slider in Settings UI

```gdscript
func set_music_volume(linear: float) -> void:
    var db := linear_to_db(linear) if linear > 0.0 else -80.0
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
```

Persisted to user://settings.cfg:

```gdscript
const SETTINGS := "user://settings.cfg"
func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "master", _master_vol)
    cfg.set_value("audio", "music", _music_vol)
    cfg.set_value("audio", "sfx", _sfx_vol)
    cfg.save(SETTINGS)
```
