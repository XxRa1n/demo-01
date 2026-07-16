extends WeaponBase

## 圣水瓶（LocatedBase·Lob）：投掷爆炸 AoE + 击退。L5 一次发射 3 瓶（数量词条 +2）。

const projectile_scene: PackedScene = preload("res://scenes/explosive_projectile.tscn")
const LOB_SPEED: float = 360.0


func _init() -> void:
	weapon_id = &"holy_water"
	display_name = "圣水瓶"
	weapon_icon_color = Color(0.7, 0.85, 1.0)
	base_damage = 14.0
	base_cooldown = 1.5
	_count_supported = true


func _fire() -> void:
	_fire_lob(projectile_scene, LOB_SPEED, _calc_damage(), 70.0, 120.0)


func _apply_special() -> void:  # L5 一次发射 3 瓶
	_count_bonus += 2
