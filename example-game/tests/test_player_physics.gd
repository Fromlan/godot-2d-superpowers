extends GutTest
## Tests for Player.compute_motion (pure function extracted from physics).

func test_compute_motion_idle_decelerates() -> void:
    var v := Vector2(200, 0)
    var result := Player.compute_motion(
        v, 0.0, true, 0.016,
        280.0, 1500.0, 1800.0, -480.0, 980.0
    )
    # Friction should reduce x velocity toward 0
    assert_lt(result.linear_velocity.x, v.x)

func test_compute_motion_right_input_accelerates() -> void:
    var v := Vector2(0, 0)
    var result := Player.compute_motion(
        v, 1.0, true, 0.016,
        280.0, 1500.0, 1800.0, -480.0, 980.0
    )
    assert_gt(result.linear_velocity.x, 0.0)

func test_compute_motion_applies_gravity_when_airborne() -> void:
    var v := Vector2(0, 0)
    var result := Player.compute_motion(
        v, 0.0, false, 0.016,
        280.0, 1500.0, 1800.0, -480.0, 980.0
    )
    assert_gt(result.linear_velocity.y, 0.0)

func test_compute_motion_no_gravity_when_grounded() -> void:
    var v := Vector2(0, 100)  # already falling
    var result := Player.compute_motion(
        v, 0.0, true, 0.016,
        280.0, 1500.0, 1800.0, -480.0, 980.0
    )
    # When grounded, gravity is NOT applied (game logic re-zeros it)
    assert_eq(result.linear_velocity.y, v.y)
