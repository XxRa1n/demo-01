extends WeaponBase

## 圣水瓶（LocatedBase·Lob）：投掷到最近敌人处爆炸 AoE，靠范围/伤害/数量成长。
## L5「一次发射3瓶」已实现（多发同投）。

const projectile_scene: PackedScene = preload("res://scenes/explosive_projectile.tscn")
const LOB_SPEED: float = 360.0

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "blast": 70.0, "knockback": 120.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "blast": 70.0, "knockback": 120.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "blast": 80.0, "knockback": 140.0},
	{"count": 1, "dmg": 1.2, "cd": 0.85, "blast": 80.0, "knockback": 140.0},
	{"count": 3, "dmg": 1.3, "cd": 0.85, "blast": 80.0, "knockback": 160.0},  # L5 一次3瓶
	{"count": 3, "dmg": 1.4, "cd": 0.85, "blast": 90.0, "knockback": 160.0},
	{"count": 3, "dmg": 1.4, "cd": 0.7, "blast": 90.0, "knockback": 180.0},
	{"count": 3, "dmg": 1.6, "cd": 0.7, "blast": 100.0, "knockback": 200.0},
]


func _init() -> void:
	weapon_id = &"holy_water"
	display_name = "圣水瓶"
	weapon_icon_color = Color(0.7, 0.85, 1.0)
	base_damage = 14.0
	base_cooldown = 1.5


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "范围 / 伤害 / 数量"


func _fire() -> void:
	var lv := get_current_level_data()
	var n := int(lv.get("count", 1))
	for _i in n:
		_fire_lob(projectile_scene, LOB_SPEED, _calc_damage(float(lv["dmg"])), float(lv["blast"]), float(lv["knockback"]))
