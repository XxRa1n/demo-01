extends WeaponBase

## 矮人榴弹炮（LocatedBase·Lob）：大范围高伤爆炸 + 强击退。L5 地震炮（更大范围）。

const projectile_scene: PackedScene = preload("res://scenes/explosive_projectile.tscn")
const MORTAR_SPEED: float = 300.0


func _init() -> void:
	weapon_id = &"mortar"
	display_name = "矮人榴弹炮"
	weapon_icon_color = Color(0.5, 0.5, 0.55)
	base_damage = 26.0
	base_cooldown = 1.8


func _fire() -> void:
	_fire_lob(projectile_scene, MORTAR_SPEED, _calc_damage(), 100.0, 260.0)


func _apply_special() -> void:  # L5 地震炮
	_size_mult *= 1.3
