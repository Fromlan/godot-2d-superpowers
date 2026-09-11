# Music Manager (autoload) (deep dive)

Reference for SKILL.md §3.

## Full autoload

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
        new_player.volume_db = 0.0
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

func _fade_out(p: AudioStreamPlayer, t: float) -> void:
    var tw := create_tween()
    tw.tween_property(p, "volume_db", -80.0, t)
    tw.tween_callback(p.queue_free)
```

Register in Project Settings → Autoload as "MusicManager".

## Use from any scene

```gdscript
# res://levels/forest.gd
func _ready() -> void:
    MusicManager.play(preload("res://assets/music/forest.ogg"))

# res://levels/cave.gd
func _ready() -> void:
    MusicManager.play(preload("res://assets/music/cave.ogg"), 0.5, 0.5)
```

## Ducking (boss roar)

```gdscript
# res://enemies/boss.gd
func _on_roar() -> void:
    MusicManager.duck_music(-12.0, 0.2)
    await get_tree().create_timer(2.0).timeout
    MusicManager.unduck_music(1.0)
```

(Requires extending MusicManager with duck_music / unduck_music; see bus-layout.md.)

## Format choice

| Format | Use |
|--------|-----|
| .ogg (Vorbis 128kbps) | BGM, long SFX |
| .wav (PCM) | Short SFX (<1s), no decode latency |
| .mp3 | Avoid (decode delay) |

## Pitfall: tween survives scene change

If MusicManager is autoload and you create_tween() inside it, the tween is owned by the autoload — survives scene changes. Good. But queue_free() the player after the fade-out tween: don't do it manually with await create_timer(fade_out).timeout because that's race-prone.
