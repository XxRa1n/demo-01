extends WeaponBase

## 旋转飞斧（OrbitEntity）：环绕玩家旋转的飞斧，持续切割接触敌人（每敌人有命中冷却）。
## 靠飞斧数量 / 半径 / 旋转速度成长。

const blade_scene: PackedScene = preload("res://effects/orbit_blade.tscn")

const LEVEL_DATA: Array = [
	{"blades": 1, "dmg": 1.0, "radius": 90.0, "speed": 3.5},
	{"blades": 1, "dmg": 1.2, "radius": 92.0, "speed": 3.6},
	{"blades": 2, "dmg": 1.2, "radius": 96.0, "speed": 3.7},
	{"blades": 2, "dmg": 1.25, "radius": 100.0, "speed": 3.8},
	{"blades": 4, "dmg": 1.3, "radius": 108.0, "speed": 4.0},   # 飞斧数8?近似为4+体积
	{"blades": 4, "dmg": 1.35, "radius": 112.0, "speed": 4.1},
	{"blades": 5, "dmg": 1.35, "radius": 116.0, "speed": 4.2},
	{"blades": 6, "dmg": 1.45, "radius": 124.0, "speed": 4.4},
]


func _init() -> void:
	weapon_id = &"spinning_axe"
	display_name = "旋转飞斧"
	weapon_icon_color = Color(0.9, 0.7, 0.3)
	base_damage = 4.0
	base_cooldown = 0.5  # 环绕实体持续存在，_fire 仅幂等同步参数


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "飞斧数量 / 半径 / 速度"


func _fire() -> void:
	var lv := get_current_level_data()
	_sync_orbit_blades(blade_scene, int(lv["blades"]), float(lv["radius"]), float(lv["speed"]), _calc_damage(float(lv["dmg"])))
