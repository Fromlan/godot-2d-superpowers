extends RefCounted
## Pure damage calculation logic. Logic layer TDD demo.
## See tests/test_damage_calc.gd.

class_name DamageCalc

## Compute final damage after armor reduction.
## Armor 0 -> take 100% damage. Armor 100 -> take 0% damage.
static func compute(raw_damage: int, armor: int) -> int:
    var reduction: float = clampf(float(armor) / 100.0, 0.0, 1.0)
    return int(round(raw_damage * (1.0 - reduction)))

## Compute critical hit. crit_chance is 0.0 - 1.0.
static func maybe_crit(damage: int, crit_chance: float, crit_multiplier: float) -> int:
    if randf() < crit_chance:
        return int(round(damage * crit_multiplier))
    return damage
