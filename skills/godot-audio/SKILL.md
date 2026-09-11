---
name: godot-audio
description: |
  Godot 4.7 音频:AudioStreamPlayer / 2D / 3D、Audio bus 布局、音乐管理 autoload、SFX pitch 与 pool、OGG 选型。Use when 提到"音频"、"SFX"、"BGM"、"Audio bus"、"音量设置"、"AudioStreamPlayer"。Do NOT use for UI 点击音效(见 godot-ui-best-practices)。Read-only knowledge。
last_reviewed: 2026-09-10
---

<!-- argument-hint: [topic, e.g. 'bus', 'BGM', '3D 定位音', 'SFX pitch'] -->

# Godot Audio (4.7)

Actionable rules for Godot 4 audio: bus layout, music management, SFX patterns, format choice. Deep dives in `references/<topic>.md`.

## 1. Pick the right player node

| Node | Use for |
|last_reviewed: 2026-09-10
---|---|
| `AudioStreamPlayer` | non-positional SFX, music, UI clicks (2D or 3D game) |
| `AudioStreamPlayer2D` | positional sound in 2D world (pans with camera, falls off with distance) |
| `AudioStreamPlayer3D` | positional sound in 3D world (HRTF panning, doppler) |
| `AudioStreamPlayer` (in CanvasLayer) | UI sound (always 2D, follows screen) |

**Default**: `AudioStreamPlayer`. Reach for 2D/3D only when you actually need spatial audio.

## 2. Bus layout (the single most important decision)

Audio buses are a mixing console: each stream plays into a bus, the bus has volume + effects, buses sum into "Master". Project Settings → Audio → Buses (or `default_bus_layout.tres`).

**Standard 4-bus starter**:

```
Master
├── Music       (low-priority BGM; gets ducked when SFX plays)
├── SFX         (combat, footsteps, impacts; many overlapping)
└── UI          (button clicks, notifications; never ducked)
```

**Why this matters**: you can change Music volume without touching SFX. You can duck Music when a boss roars (see Rule 5). You can add a global reverb send to SFX only. A single bus per category is the right starting point.

**In code, set bus on a player**:
```gdscript
sfx_player.bus = "SFX"
music_player.bus = "Music"
```

## 3. Music manager as autoload (single source of truth)

Music is a cross-scene concern. Put a music manager in autoload (`Project Settings → Autoload → "MusicManager"`):

```gdscript
# res://autoloads/music_manager.gd
extends Node

var _current_player: AudioStreamPlayer
var _current_track: AudioStream

func play(track: AudioStream, fade_in := 1.0, fade_out := 1.0) -> void:
    if _current_track == track:
        return
    var new_player := AudioStreamPlayer.new()
    new_player.bus = "Music"
    new_player.stream = track
    add_child(new_player)
    new_player.play()
    if _current_player:
        _crossfade(_current_player, new_player, fade_out, fade_in)
    else:
        new_player.volume_db = 0.0  # 0 dB full volume; linear_to_db(0) = -inf
    _current_player = new_player
    _current_track = track

func stop(fade_out := 1.0) -> void:
    if _current_player:
        _fade_out(_current_player, fade_out)
        _current_player = null
        _current_track = null

func _crossfade(old: AudioStreamPlayer, new: AudioStreamPlayer, fade_out: float, fade_in: float) -> void:
    if fade_out > 0:
        var t := create_tween()
        t.tween_property(old, "volume_db", -80.0, fade_out)
        t.tween_callback(old.queue_free)
    else:
        old.queue_free()
    new.volume_db = -80.0
    var t := create_tween()
    t.tween_property(new, "volume_db", 0.0, fade_in)

func _fade_out(player: AudioStreamPlayer, time: float) -> void:
    var t := create_tween()
    t.tween_property(player, "volume_db", -80.0, time)
    t.tween_callback(player.queue_free)
```

**Crossfade prevents the "click" between tracks**(instant volume change produces a pop)。注意 0 dB = full volume; -80.0 dB 接近静音(多数音频 API 在这之下都 clamp)。`linear_to_db(1.0) = 0`,`linear_to_db(0.0) = -inf`(永远别对 0 调 linear_to_db)。

## 4. SFX random pitch for procedural variety

The same hit sound 10 times in a row gets boring. Randomize pitch by ±10-20%:

```gdscript
func play_hit_sfx() -> void:
    var player := AudioStreamPlayer.new()
    player.bus = "SFX"
    player.stream = preload("res://audio/sfx/hit.ogg")
    player.pitch_scale = randf_range(0.9, 1.1)   # ±10% pitch
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()
```

`pitch_scale = 1.0` is normal speed. `0.5` = octave down + half speed. `2.0` = octave up + double speed. SFX typically want 0.9-1.1 to keep them recognizable.

**Why this works for repeated sounds**: even though the sample is identical, the pitch shift makes each instance feel distinct. The brain doesn't pattern-match as fast.

## 5. Duck the music when SFX spike (boss attack, ultimate)

When a boss uses a special ability, you want the music to drop for a moment so the SFX punches through:

```gdscript
func duck_music(target_db := -12.0, time := 0.2) -> void:
    var music_bus_idx := AudioServer.get_bus_index("Music")
    # AudioServer is a singleton, not a Node; Tween cannot directly tween its
    # properties. Use tween_method with a setter Callable instead.
    var set_bus := _set_bus_volume.bind(music_bus_idx)
    var t := create_tween()
    t.tween_method(set_bus, AudioServer.get_bus_volume_db(music_bus_idx), target_db, time)
    t.tween_interval(0.5)  # hold ducked
    t.tween_method(set_bus, target_db, 0.0, 0.5)  # restore

static func _set_bus_volume(bus_idx: int, db: float) -> void:
    AudioServer.set_bus_volume_db(bus_idx, db)
```

**Why `tween_method` not `tween_property(AudioServer, ...)`**: `AudioServer` is a singleton, not a Node. Its properties aren't tweenable directly. Use `tween_method` with a callback that calls `set_bus_volume_db`.

`AudioServer.get_bus_index(...)` 在 setter 里每帧调用会浪费;用 `.bind(music_bus_idx)` 把 bus_idx 捕获到 Callable 里,setter 直接用绑定值。

## 6. Format: OGG for everything except music licensing

| Format | Use |
|---|---|
| OGG Vorbis (`.ogg`) | default for SFX and music; small files, good quality, loop points supported |
| WAV (`.wav`) | only when you need lossless (rare; usually editing source) |
| MP3 (`.mp3`) | music licensing compatibility (some labels require MP3 delivery); not for SFX |
| OPUS | newer alternative to OGG, smaller; Godot 4 supports it |

**Anti-pattern**: MP3 for SFX. MP3 has 100-200 ms latency on first play (decoding delay), and is larger than OGG for the same quality. Use OGG for SFX; reserve MP3 for music if your licensing demands it.

**Anti-pattern**: raw WAV in final builds. WAV is 10× larger than OGG. Always encode to OGG before shipping.

## 7. Volume settings (Settings menu)

Per-bus volume is the standard:

```gdscript
func set_master_volume(linear: float) -> void:
    # linear: 0.0 (silent) → 1.0 (full)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(linear))

func get_master_volume() -> float:
    return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))

func set_music_volume(linear: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(linear))
```

Persist to `user://settings.cfg` (ConfigFile) or `user://settings.json`:

```gdscript
const SETTINGS_PATH := "user://settings.cfg"

func save_volume() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "master", get_master_volume())
    cfg.set_value("audio", "music", get_music_volume())
    cfg.set_value("audio", "sfx", get_sfx_volume())
    cfg.save(SETTINGS_PATH)

func load_volume() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SETTINGS_PATH) != OK:
        return
    var master: float = cfg.get_value("audio", "master", 1.0)
    set_master_volume(master)
```

A slider in the Settings UI calls `set_master_volume(0.5)` on `value_changed` and `save_volume()` on `mouse_exited` (or `tween.tween_callback` to debounce).

## 8. SFX player pool (avoid instantiating per-play)

For repeated SFX (hit, click, footstep), instantiating a new `AudioStreamPlayer` per call works but creates GC pressure. Pool a small set of players:

```gdscript
class_name SfxPool extends Node
const POOL_SIZE := 8

var _pool: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
    for i in POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        _pool.append(p)

func play(stream: AudioStream, pitch := 1.0) -> void:
    var p := _pool[_next]
    _next = (_next + 1) % POOL_SIZE
    p.stream = stream
    p.pitch_scale = pitch
    p.play()
```

8 players is enough for most SFX. If a sound is currently playing, it's cut short (overlap). For overlapping without cutoff, use more players or create-on-demand (and `queue_free` on `finished`).

## 9. `AudioStreamPlayer.finished` signal

Every player has a `finished` signal that fires when playback ends. Use it to clean up:

```gdscript
var p := AudioStreamPlayer.new()
p.bus = "SFX"
p.stream = my_sfx
add_child(p)
p.finished.connect(p.queue_free)
p.play()
```

If you `queue_free` manually after a fixed timer instead, the sound gets cut off if the audio engine takes longer than expected. Use `finished`.

For long sounds (music, ambient): don't connect `finished → queue_free`; let the player persist for the lifetime of the manager.

## 10. 3D audio: distance falloff and HRTF

For 3D positional audio (`AudioStreamPlayer3D`):

```gdscript
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

# In the inspector:
# - max_distance: how far the sound is audible (e.g. 50)
# - unit_size: world unit scale (e.g. 1 meter = 1)
# - attenuation_model: inverse_distance, logarithmic, etc.
# - panning_strength: 0 = no panning, 1 = full HRTF
```

Default falloff is "Inverse Distance" which is fine for most games. "Logarithmic" is more realistic but louder near the source. For music, use `attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED` to make it global.

## Common bug patterns

| Symptom | Root cause | Rule |
|---|---|---|
| Music and SFX volume tied together | All on "Master" only | 2 |
| Music pops between tracks | No crossfade | 3 |
| Same SFX 10× in 2s feels monotonous | No pitch variation | 4 |
| Boss ability lost in music | No duck | 5 |
| First SFX plays late | MP3 decoding delay | 6 |
| Volume slider only changes SFX | Hardcoded bus, not configurable | 7 |
| 100 SFX playing → frame stutter | Per-play instantiation + GC | 8 |
| `node not found` after play | Manually queue_free'd before finished | 9 |
| Footstep audible from across the map | `max_distance` too high | 10 |

## Reference index

- `references/bus-layout.md` — bus configuration in `default_bus_layout.tres`, effect chain, sends
- `references/music-manager.md` — full autoload with crossfade, ducking, persistence
- `references/sfx-patterns.md` — pitch random, player pool, throttling, 3D positional SFX

## Output contract

Read-only knowledge. Apply the rules when building / fixing Godot audio. Don't generate new skills; don't run scripts; don't modify files outside the active Godot project.

## Failure handling

If an audio bug doesn't match any rule above, the bug is either:
- Wrong bus assigned (Rule 2) — print `player.bus` and `AudioServer.bus_count`
- File not imported (Rule 6) — check `.import` sidecar in FileSystem panel
- Effect chain order wrong (Rule 2) — bus effects apply in inspector order; first = first
- Audio context reset (rare) — re-call `AudioServer.set_bus_volume_db` on resume-from-pause

If still stuck, fall back to: print every `AudioStreamPlayer.bus` in the scene, check each bus's `volume_db` and `mute` state via `AudioServer.get_bus_*`.
