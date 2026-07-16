extends WeaponBase

## 环绕圣经（OrbitEntity）：环绕玩家的圣典。L5 发射短米字激光（8 向光束）。

const blade_scene: PackedScene = preload("res://effects/orbit_blade.tscn")


func _init() -> void:
	weapon_id = &"holy_book"
	display_name = "环绕圣经"
	weapon_icon_color = Color(0.95, 0.92, 0.6)
	base_damage = 5.0
	base_cooldown = 0.5
	_count_supported = true


func _fire() -> void:
	_sync_orbit_blades(blade_scene, 2, 110.0, 2.6, _calc_damage())
	if _l5_active:
		# 米字激光：8 个方向（每 45°）
		var dirs: Array = []
		for i in 8:
			dirs.append(Vector2.from_angle(float(i) * (PI / 4.0)))
		_fire_beams(dirs, _calc_damage() * 2.5, 420.0 * _size_mult, 12.0, 0.4, _gem_element())


func _apply_special() -> void:  # L5 发射短米字激光
	pass
