extends WeaponBase

## 激光（Beam）：锁定最近敌人的持续光束，按帧 DPS。L5 发射 X 型光线（四向对角光束）。

func _init() -> void:
	weapon_id = &"laser"
	display_name = "激光"
	weapon_icon_color = Color(0.4, 0.8, 1.0)
	base_damage = 12.0
	base_cooldown = 1.5


func _fire() -> void:
	var dps: float = _calc_damage() * 3.0
	var length: float = 540.0 * _size_mult
	var width: float = 16.0 * _size_mult
	var el: int = _gem_element()
	if _l5_active:
		# X 型光线：四个对角方向
		_fire_beams([
			Vector2(1, 1).normalized(),
			Vector2(1, -1).normalized(),
			Vector2(-1, 1).normalized(),
			Vector2(-1, -1).normalized(),
		], dps, length, width, 1.0, el)
	else:
		var beam := Beam.new()
		beam.setup(dps, length, width, 1.0, el, self)
		beam.global_position = game_manager.player.global_position
		projectiles_container.add_child(beam)


func _apply_special() -> void:  # L5 发射 X 型光线
	pass
