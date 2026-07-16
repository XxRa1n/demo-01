extends WeaponBase

## 火枪（ProjectileBase·Seek）：单发高伤远程射击。L5 空中掉落（近似为高伤）。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const MUSKET_SPEED: float = 900.0


func _init() -> void:
	weapon_id = &"musket"
	display_name = "火枪"
	weapon_icon_color = Color(0.3, 0.3, 0.3)
	base_damage = 22.0
	base_cooldown = 1.4
	_pierce_supported = true


func _fire() -> void:
	_fire_seek_spread(projectile_scene, 1, 0.0, MUSKET_SPEED, _calc_damage(), 0)


func _apply_special() -> void:  # L5 向空中发射子弹掉落
	_dmg_mult *= 1.5
