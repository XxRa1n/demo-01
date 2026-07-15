extends WeaponBase

## 环绕圣经（OrbitEntity）：环绕玩家的圣典，持续命中接触敌人。
## 与旋转飞斧同为环绕类，差异在数值（更慢更广、数量多）。
## L5「短米字激光」留待后续。

const blade_scene: PackedScene = preload("res://effects/orbit_blade.tscn")

const LEVEL_DATA: Array = [
	{"blades": 2, "dmg": 1.0, "radius": 110.0, "speed": 2.6},
	{"blades": 2, "dmg": 1.2, "radius": 112.0, "speed": 2.7},
	{"blades": 3, "dmg": 1.2, "radius": 116.0, "speed": 2.8},
	{"blades": 3, "dmg": 1.25, "radius": 120.0, "speed": 2.9},
	{"blades": 4, "dmg": 1.3, "radius": 128.0, "speed": 3.0},
	{"blades": 4, "dmg": 1.35, "radius": 132.0, "speed": 3.1},
	{"blades": 5, "dmg": 1.35, "radius": 136.0, "speed": 3.2},
	{"blades": 6, "dmg": 1.45, "radius": 144.0, "speed": 3.4},
]


func _init() -> void:
	weapon_id = &"holy_book"
	display_name = "环绕圣经"
	weapon_icon_color = Color(0.95, 0.92, 0.6)
	base_damage = 5.0
	base_cooldown = 0.5


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "数量 / 半径 / 伤害"


func _fire() -> void:
	var lv := get_current_level_data()
	_sync_orbit_blades(blade_scene, int(lv["blades"]), float(lv["radius"]), float(lv["speed"]), _calc_damage(float(lv["dmg"])))
