extends WeaponBase

## 环绕圣经（OrbitEntity）：环绕玩家的圣典。L5 短米字激光（近似多发）。

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


func _apply_special() -> void:  # L5 发射短米字激光
	_count_bonus += 2
