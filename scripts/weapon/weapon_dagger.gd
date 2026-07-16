extends WeaponBase

## 匕首（ProjectileBase·Rapid）：高频低伤飞刀。L5 最远射程处旋转（穿透）。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const DAGGER_SPEED: float = 760.0


func _init() -> void:
	weapon_id = &"dagger"
	display_name = "匕首"
	weapon_icon_color = Color(0.85, 0.85, 0.9)
	base_damage = 5.0
	base_cooldown = 0.6
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	_fire_seek_spread(projectile_scene, 1, 0.12, DAGGER_SPEED, _calc_damage(), 0)


func _apply_special() -> void:  # L5 最远射程处旋转
	_pierce_bonus += 2
