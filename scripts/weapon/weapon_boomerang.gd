extends WeaponBase

## 回旋镖（ProjectileBase·Seek）：高速穿透飞镖（折返行为待精修）。L5 黄金回旋（多发多穿）。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const BOOMERANG_SPEED: float = 520.0
const BASE_PIERCE: int = 2


func _init() -> void:
	weapon_id = &"boomerang"
	display_name = "回旋镖"
	weapon_icon_color = Color(0.95, 0.75, 0.2)
	base_damage = 9.0
	base_cooldown = 1.2
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	_fire_seek_spread(projectile_scene, 1, 0.25, BOOMERANG_SPEED, _calc_damage(), BASE_PIERCE)


func _apply_special() -> void:  # L5 黄金回旋
	_count_bonus += 2
	_pierce_bonus += 2
