extends WeaponBase

## 弩箭（ProjectileBase·Seek）：单发高伤穿透弩矢。L5 诸葛连弩（一次连射多发）。

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
	# L5 诸葛连弩：一次连射 3 发（小幅扩散）
	var count: int = 3 if _l5_active else 1
	_fire_seek_spread(projectile_scene, count, 0.12, BOLT_SPEED, _calc_damage(), BASE_PIERCE)


func _apply_special() -> void:  # L5 诸葛连弩
	pass
