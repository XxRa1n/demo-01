extends WeaponBase

## 弩箭（ProjectileBase·Seek）：单发高伤穿透弩矢。L5 诸葛连弩（高伤多穿）。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const BOLT_SPEED: float = 800.0
const BASE_PIERCE: int = 1


func _init() -> void:
	weapon_id = &"crossbow"
	display_name = "弩箭"
	weapon_icon_color = Color(0.45, 0.3, 0.15)
	base_damage = 16.0
	base_cooldown = 1.3
	_pierce_supported = true


func _fire() -> void:
	_fire_seek_spread(projectile_scene, 1, 0.0, BOLT_SPEED, _calc_damage(), BASE_PIERCE)


func _apply_special() -> void:  # L5 诸葛连弩
	_dmg_mult *= 1.4
	_pierce_bonus += 2
