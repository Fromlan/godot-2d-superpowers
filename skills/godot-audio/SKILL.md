---
name: godot-audio
description: |
  Godot 4.7 音频:AudioStreamPlayer / 2D / 3D、Audio bus 布局、音乐管理 autoload、SFX pitch 与 pool、随吉选型。Use when 提到"音频"、"SFX"、"BGM"、"Audio bus"、"音量设置"、"AudioStreamPlayer"。Do NOT use for UI 点击音效(见 godot-ui-best-practices)。Read-only knowledge。
last_reviewed: 2026-09-11
---

<!-- argument-hint: [topic, e.g. 'bus', 'BGM', '3D 定位音', 'SFX pitch'] -->

# Godot 音频 (4.7)

Godot 4 音频的实操规则:bus 布局、音乐管理、SFX 模式、格式选择。深入阅读见 `references/<topic>.md`。

## 1. 选对 Player 节点

| 节点 | 用途 |
|------|------|
| `AudioStreamPlayer` | 非定位 SFX、音乐、UI 点击(2D 或 3D 游戏) |
| `AudioStreamPlayer2D` | 2D 世界中定位音(随镜头平移,随距离衰减) |
| `AudioStreamPlayer3D` | 3D 世界中定位音(HRTF 平移,多普勒) |
| `AudioStreamPlayer`(在 CanvasLayer 中) | UI 音(始终 2D,随屏幕) |

**默认**:`AudioStreamPlayer`。仅当你需要空间音才用 2D / 3D。

## 2. Bus 布局(单一最重要的决定)

Audio bus 是混音台:每个 stream 播到一个 bus,bus 有音量 + 效果,bus 汇总到 "Master"。Project Settings → Audio → Buses(或 `default_bus_layout.tres`)。

**标准 4-bus 入门**:

```
Master
├── Music       (低优先级 BGM;SFX 播放时 ducked)
├── SFX         (战斗、脚步、冲击;多个重叠)
└── UI          (按钮点击、通知;永不 duck)
```

**为什么重要**:改 Music 音量不动 SFX。Boss 吼时可 duck Music(见规则 5)。仅给 SFX 加全局混响 send。

**代码中设 player bus**:

```gdscript
sfx_player.bus = "SFX"
music_player.bus = "Music"
```

## 3. 音乐管理作为 autoload(唯一真相源)

音乐是跨场景关注。autoload 放音乐管理器(Project Settings → Autoload → "MusicManager"):

```gdscript
# res://autoloads/music_manager.gd
extends Node

var _current_player: Player
var _current_track: Stream

func play(track: Stream, fade_in := 1.0, fade_out := 1.0) -> void:
    if _current_track == track:
        return
    var new_player := Player.new()
    new_player.bus = "Music"
    new_player.stream = track
    add_child(new_player)
    new_player.play()
    if _current_player:
        _crossfade(_current_player, new_player, fade_out, fade_in)
    else:
        new_player.volume_db = 0.0  # 0 dB 满音量;linear_to_db(0) = -inf
    _current_player = new_player
    _current_track = track

func stop(fade_out := 1.0) -> void:
    if _current_player:
        _fade_out(_current_player, fade_out)
        _current_player = null
        _current_track = null

func _crossfade(old: Player, new: Player, fade_out: float, fade_in: float) -> void:
    if fade_out > 0:
        var t := create_tween()
        t.tween_property(old, "volume_db", -80.0, fade_out)
        t.tween_callback(old.queue_free)
    else:
        old.queue_free()
    new.volume_db = -80.0
    var t := create_tween()
    t.tween_property(new, "volume_db", 0.0, fade_in)

func _fade_out(player: Player, time: float) -> void:
    var t := create_tween()
    t.tween_property(player, "volume_db", -80.0, time)
    t.tween_callback(player.queue_free)
```

**交叉淡入防止轨道间的「咔哒」**(瞬时音量变化产生 pop)。0 dB = 满音量;-80.0 dB 接近静音(多数音频 API 在这之下都 clamp)。`linear_to_db(1.0) = 0`,`linear_to_db(0.0) = -inf`(永远别对 0 调 linear_to_db)。

## 4. SFX 随机音高产生多样性

同一个受击音播 10 次会单调。随机 ±10-20% 音高:

```gdscript
func play_hit_sfx() -> void:
    var player := Player.new()
    player.bus = "SFX"
    player.stream = preload("res://audio/sfx/hit.ogg")
    player.pitch_scale = randf_range(0.9, 1.1)   # ±10% 音高
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()
```

`pitch_scale = 1.0` 是常速。`0.5` = 低八度 + 半速。`2.0` = 高八度 + 双速。SFX 通常 0.9-1.1 保持可识别。

**为什么对重复音有用**:即使样本相同,频率偏移让每个实例感觉不同。大脑的模板匹配没那么快。

## 5. SFX 峰值时 duck 音乐(Boss 攻击、终结技)

Boss 用大招时,你希望音乐短暂下降,让 SFX 突出:

```gdscript
func duck_music(target_db := -12.0, time := 0.2) -> void:
    var music_bus_idx := AudioServer.get_bus_index("Music")
    # tween the bus volume down
    var t := create_tween()
    t.tween_method(
        func(v: float) -> void: AudioServer.set_bus_volume_db(music_bus_idx, v),
        AudioServer.get_bus_volume_db(music_bus_idx), target_db, time
    )
    # Caller triggers unduck() after a delay
```

`target_db = -12` 是常见的感知降量,不让音乐听不见。

## 6. 格式选择(.ogg vs .wav vs .mp3)

| 格式 | 用途 |
|------|------|
| `.ogg`(Vorbis 128kbps) | BGM、长 SFX |
| `.wav`(PCM) | 短 SFX(< 1s)、无解码延迟 |
| `.mp3` | 可用;短 SFX 仍优先 `.ogg`/`.wav` |

短音效 < 1s 用 `.wav`(无解码延迟);长音效 / BGM 用 `.ogg`(Vorbis)。`.mp3` Godot 4 原生支持,非必要不作为默认。

## 7. 音量滑块 + 持久化到 `user://settings.cfg`

```gdscript
func set_master_volume(linear: float) -> void:
    # linear: 0.0 (silent) → 1.0 (full)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(linear))

func get_master_volume() -> float:
    return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))

func set_music_volume(linear: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(linear))
```

持久化到 `user://settings.cfg`(ConfigFile)或 `user://settings.json`:

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

设置 UI 中的滑块在 `value_changed` 调 `set_master_volume(0.5)`,`mouse_exited`(或 `tween.tween_callback` 防抖)调 `save_volume()`。

官方参考:[AudioServer](https://docs.godotengine.org/en/stable/classes/class_audioserver.html) · [Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html)

## 8. SFX player pool(避免每次播放新建)

对重复 SFX(受击、点击、脚步),每次播放新建 `AudioStreamPlayer` 能用但有 GC 压力。pool 8 个 player:

```gdscript
class_name SfxPool extends Node
const POOL_SIZE := 8

var _pool: Array[Player] = []
var _next := 0

func _ready() -> void:
    for i in POOL_SIZE:
        var p := Player.new()
        p.bus = "SFX"
        add_child(p)
        _pool.append(p)

func play(stream: Stream, pitch := 1.0) -> void:
    var p := _pool[_next]
    _next = (_next + 1) % POOL_SIZE
    p.stream = stream
    p.pitch_scale = pitch
    p.play()
```

8 个 player 足够大多数 SFX。若一个声音正在播放,会被截断(重叠)。要重叠不截断,用更多 player 或按需创建 + `finished` 时 `queue_free`。

## 9. `AudioStreamPlayer.finished` 信号

每个 player 有 `finished` 信号,播完时触发。用它清理:

```gdscript
var p := Player.new()
p.bus = "SFX"
p.stream = my_sfx
add_child(p)
p.finished.connect(p.queue_free)
p.play()
```

若用固定定时器手动 `queue_free`,音频引擎比预期慢时声音被截断。用 `finished`。

对长音(音乐、环境音):不要连 `finished → queue_free`;让 player 在管理器生命周期内持续存在。

## 10. 3D 音频:距离衰减与声像

对 3D 定位音(`AudioStreamPlayer3D`):

```gdscript
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

# In the inspector:
# - max_distance: 超过则完全听不到 (0 = 不限制; e.g. 50)
# - unit_size: 衰减尺度 (default 10.0)
# - attenuation_model: ATTENUATION_INVERSE_DISTANCE (0), LOGARITHMIC (2), DISABLED (3)...
# - panning_strength: 声像强度系数 (default 1.0;0 = 禁用立体声声像)
```

默认衰减「Inverse Distance」对多数游戏够用。「Logarithmic」更真实但近源处更响。音乐用 `attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED` 设为全局。

官方参考:[AudioStreamPlayer3D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html) · [Audio streams](https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html)

## 常见 bug 模式

| 症状 | 根因 | 修复 |
|------|------|------|
| 音乐和 SFX 音量绑在一起 | 都在 "Master" | 拆为 Music / SFX / UI bus |
| 音乐间 pop | 没有交叉淡入 | 用 Tween 做交叉淡入 |
| 同 SFX 2 秒内 10 次单调 | 没有音高变化 | 用 `randf_range(0.9, 1.1)` 随机音高 |
| Boss 大招被音乐淹 | 没有 duck | SFX 大声时 duck Music -12 dB |
| 首 SFX 播放延迟 | MP3 解码 | 用 OGG 或 preload |
| 音量滑块只改 SFX | 硬编码 bus,不可配 | 让滑块改对应 bus |
| 100 SFX 同时播放 → 帧卡顿 | 每次 `new` + GC | 用 pool |
| play 后 `node not found` | 在 finished前 手动 `queue_free` | 用 `finished.connect(queue_free)` |
| 脚步能从地图对面听到 | `max_distance` 太高 | 调低到游戏内相关范围 |

## 参考索引

- `references/bus-layout.md` — bus 配置 `default_bus_layout.tres`、效果链、sends
- `references/music-manager.md` — 完整 autoload 跨场景音乐切换、ducking、persistence
- `references/sfx-patterns.md` — pitch 随机、player pool、节流、3D 定位 SFX

## 输出契约

只读知识。在写 / 改 Godot 音频时应用规则。不要生成新 skill;不要跑脚本;不要修改活动 Godot 项目外的文件。

## 失败处理

如果音频 bug 不匹配上述任一规则:

- bus 分配错(规则 2)— 打印 `player.bus` 和 `AudioServer.bus_count`
- 文件未导入(规则 6)— 在 FileSystem panel 检查 `.import` 侧车
- 效果链顺序错(规则 2)— bus 效果按 inspector 顺序应用;先列的先作用
- 音频上下文重置(罕见)— 暂停恢复时再调 `AudioServer.set_bus_volume_db`

还卡住的话,回退到:打印场景里每个 `AudioStreamPlayer.bus`,通过 `AudioServer.get_bus_*` 检查每个 bus 的 `volume_db` 和 `mute` 状态。

官方参考:[AudioServer](https://docs.godotengine.org/en/stable/classes/class_audioserver.html) · [AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html) · [AudioStreamPlayer2D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer2d.html) · [AudioStreamPlayer3D](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html) · [Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html) · [Audio streams](https://docs.godotengine.org/en/stable/tutorials/audio/audio_streams.html)
