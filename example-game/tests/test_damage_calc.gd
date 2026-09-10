extends GutTest
## Tests for DamageCalc (logic layer, strict TDD per godot-coding-2d §7.1).

func test_compute_zero_armor_takes_full_damage() -> void:
    assert_eq(DamageCalc.compute(100, 0), 100)

func test_compute_full_armor_blocks_all() -> void:
    assert_eq(DamageCalc.compute(100, 100), 0)

func test_compute_half_armor_halves_damage() -> void:
    assert_eq(DamageCalc.compute(100, 50), 50)

func test_compute_clamps_armor_above_100() -> void:
    assert_eq(DamageCalc.compute(100, 150), 0)

func test_compute_clamps_armor_below_zero() -> void:
    assert_eq(DamageCalc.compute(100, -50), 100)

func test_compute_rounds_fractional_results() -> void:
    # 33% reduction on 100 -> 67
    assert_eq(DamageCalc.compute(100, 33), 67)

func test_maybe_crit_no_crit() -> void:
    # crit_chance = 0 -> never crits
    for i in 100:
        var result := DamageCalc.maybe_crit(100, 0.0, 2.0)
        assert_eq(result, 100)

func test_maybe_crit_always_crits() -> void:
    # crit_chance = 1 -> always crits
    for i in 10:
        var result := DamageCalc.maybe_crit(50, 1.0, 2.0)
        assert_eq(result, 100)
