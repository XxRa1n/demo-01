extends WeaponBase

## 旋转飞斧（OrbitEntity）：环绕玩家旋转的飞斧，持续切割。L5 飞斧数量 +3。

const blade_scene: PackedScene = preload("res://effects/orbit_blade.tscn")


func _init() -> void:
	weapon_id = &"spinning_axe"
	display_name = "旋转飞斧"
	weapon_icon_color = Color(0.9, 0.7, 0.3)
	base_damage = 4.0
	base_cooldown = 0.5  # 环绕实体持续存在，_fire 仅幂等同步
	_count_supported = true


func _fire() -> void:
	_sync_orbit_blades(blade_scene, 1, 90.0, 3.5, _calc_damage())


func _apply_special() -> void:  # L5 增加飞斧数量为 8
	_count_bonus += 3
