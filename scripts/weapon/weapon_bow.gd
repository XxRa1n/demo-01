extends WeaponBase

## 弓箭（ProjectileBase·Spread）：扇形多发箭矢。升级走固定模板；L5 万箭齐发（多发）。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const BASE_COUNT: int = 3
const SPREAD: float = 0.20
const ARROW_SPEED: float = 620.0
const BASE_PIERCE: int = 0


func _init() -> void:
	weapon_id = &"bow"
	display_name = "弓箭"
	weapon_icon_color = Color(0.6, 0.4, 0.2)
	base_damage = 7.0
	base_cooldown = 1.1
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	_fire_seek_spread(projectile_scene, BASE_COUNT, SPREAD, ARROW_SPEED, _calc_damage(), BASE_PIERCE)


func _apply_special() -> void:  # L5 万箭齐发
	_count_bonus += 3
