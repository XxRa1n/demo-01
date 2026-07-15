extends WeaponBase

## 火枪（ProjectileBase·Seek）：单发高伤远程射击，靠伤害成长。
## L5「向空中发射子弹随机掉落砸敌」留待后续实现，本批为强单发。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const MUSKET_SPEED: float = 900.0

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "pierce": 0},
	{"dmg": 1.25, "cd": 1.0, "pierce": 0},
	{"dmg": 1.25, "cd": 1.0, "pierce": 1},
	{"dmg": 1.25, "cd": 0.85, "pierce": 1},
	{"dmg": 1.6, "cd": 0.85, "pierce": 1},   # 空中掉落(近似为高伤)
	{"dmg": 1.7, "cd": 0.85, "pierce": 2},
	{"dmg": 1.7, "cd": 0.7, "pierce": 2},
	{"dmg": 2.0, "cd": 0.7, "pierce": 2},
]


func _init() -> void:
	weapon_id = &"musket"
	display_name = "火枪"
	weapon_icon_color = Color(0.3, 0.3, 0.3)
	base_damage = 22.0
	base_cooldown = 1.4


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "伤害 / 穿透 / 冷却"


func _fire() -> void:
	var lv := get_current_level_data()
	_fire_seek_spread(projectile_scene, 1, 0.0, MUSKET_SPEED, _calc_damage(float(lv["dmg"])), int(lv["pierce"]))
