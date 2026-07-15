extends WeaponBase

## 弩箭（ProjectileBase·Seek）：单发高伤穿透弩矢，靠伤害与穿透成长。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const BOLT_SPEED: float = 800.0

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "pierce": 1},
	{"dmg": 1.2, "cd": 1.0, "pierce": 1},
	{"dmg": 1.2, "cd": 1.0, "pierce": 2},
	{"dmg": 1.2, "cd": 0.85, "pierce": 2},
	{"dmg": 1.5, "cd": 0.85, "pierce": 3},   # 诸葛连弩：高伤多穿
	{"dmg": 1.6, "cd": 0.85, "pierce": 3},
	{"dmg": 1.6, "cd": 0.7, "pierce": 3},
	{"dmg": 1.8, "cd": 0.7, "pierce": 4},
]


func _init() -> void:
	weapon_id = &"crossbow"
	display_name = "弩箭"
	weapon_icon_color = Color(0.45, 0.3, 0.15)
	base_damage = 16.0
	base_cooldown = 1.3


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "伤害 / 穿透 / 冷却"


func _fire() -> void:
	var lv := get_current_level_data()
	_fire_seek_spread(projectile_scene, 1, 0.0, BOLT_SPEED, _calc_damage(float(lv["dmg"])), int(lv["pierce"]))
