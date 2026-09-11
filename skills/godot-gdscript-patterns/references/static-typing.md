# Static Typing (deep dive)

Reference for SKILL.md §1 + §10.

## Typed vs untyped: the real cost

```gdscript
# Untyped (Variant dispatch)
var x = 5
var s = "hello"
var v = x + s  # Variant add; slow, allocates

# Typed (direct path)
var x: int = 5
var s: String = "hello"
# var v: int = x + s  # analyzer error at edit time
```

| Aspect | Untyped | Typed |
|--------|---------|-------|
| Runtime | Variant dispatch (boxing) | Direct call, near-C |
| Static analysis | warnings | errors at edit time |
| Memory | Variant overhead (24 bytes each) | stack or direct member |
| Editor autocompletion | partial | full |

## When to type Variant

Only at the boundary:

- JSON.parse_string returns Variant — type it
- Dictionary values where types are heterogeneous
- Signal parameters that legitimately take multiple types (rare)

```gdscript
# Boundary
var raw: Variant = JSON.parse_string(text)

# After parsing, narrow
if typeof(raw) == TYPE_DICTIONARY:
    var dict: Dictionary = raw
    var name: String = dict.get("name", "")
    var hp: int = dict.get("hp", 0)
```

## Typed collections (Godot 4.4+)

```gdscript
var stats: Dictionary[String, int] = {"hp": 100, "attack": 50, "defense": 30}
var pieces: Array[Piece] = []
stats["hp"] = "100"  # analyzer error: expected int, got String
```

## Analyzer flags

| Warning | Meaning | Fix |
|---------|---------|-----|
| UNTYPED_DECLARATION | var without type | add : Type |
| INFERRED_DECLARATION | := value (slight cost) | use : Type = value |
| UNSAFE_METHOD_ACCESS | untyped receiver | type the variable |
| UNSAFE_PROPERTY_ACCESS | same | same |
| UNSAFE_CALL_ARGUMENT | passing Variant to typed param | narrow before passing |

## Constants vs exports

| | Where | When |
|--|-------|------|
| const X := 5 | script, compile-time | rarely changes |
| @export var x: int = 5 | inspector | designer-tunable |
| var x: int = 5 | instance, runtime | mutable state |

Don't make everything @export — designers drown in noise. Reserve for 5-10 values per script.

## When untyped is fine

- One-off debug scripts (print loop)
- Truly dynamic data structures where the schema is unknown
- Tool scripts that introspect arbitrary types

For everything else: type aggressively.
