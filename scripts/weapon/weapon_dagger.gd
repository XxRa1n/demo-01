extends WeaponBase

## 匕首（ProjectileBase·Rapid）：高频低伤飞刀，靠攻速与弹数成长。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const DAGGER_SPEED: float = 760.0

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "pierce": 0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "pierce": 0},
	{"count": 2, "dmg": 1.2, "cd": 1.0, "pierce": 0},
	{"count": 2, "dmg": 1.2, "cd": 0.7, "pierce": 0},
	{"count": 2, "dmg": 1.3, "cd": 0.7, "pierce": 1},   # 最远射程处旋转(穿透)
	{"count": 3, "dmg": 1.3, "cd": 0.7, "pierce": 1},
	{"count": 3, "dmg": 1.3, "cd": 0.55, "pierce": 1},
	{"count": 4, "dmg": 1.4, "cd": 0.55, "pierce": 1},
]


func _init() -> void:
	weapon_id = &"dagger"
	display_name = "匕首"
	weapon_icon_color = Color(0.85, 0.85, 0.9)
	base_damage = 5.0
	base_cooldown = 0.6


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "攻速 / 弹数 / 穿透"


func _fire() -> void:
	var lv := get_current_level_data()
	_fire_seek_spread(projectile_scene, int(lv["count"]), 0.12, DAGGER_SPEED, _calc_damage(float(lv["dmg"])), int(lv["pierce"]))
