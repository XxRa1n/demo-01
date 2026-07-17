extends WeaponBase

## 旋转飞斧（OrbitEntity）：环绕玩家旋转的飞斧，持续切割。
## L5 增加飞斧数量为 8 + 体积 + 速度，持续 3s（周期性爆发）。

const blade_scene: PackedScene = preload("res://effects/orbit_blade.tscn")


func _init() -> void:
	weapon_id = &"spinning_axe"
	display_name = "旋转飞斧"
	weapon_icon_color = Color(0.9, 0.7, 0.3)
	base_damage = 4.0
	base_cooldown = 0.5  # 环绕实体持续存在，_fire 仅幂等同步


func _fire() -> void:
	# L5：周期性爆发到 8 把(基础1+临时7) + 放大，持续 3s，冷却 6s
	if _l5_active and not _buff_active and _buff_cd <= 0.0:
		_start_buff(1.0, 1.3, 7, 3.0)
		_buff_cd = 6.0
	_sync_orbit_blades(blade_scene, 1, 90.0, 3.5, _calc_damage())


func _apply_special() -> void:  # L5 增加飞斧数量为 8 + 体积 + 速度，持续 3s
	pass
