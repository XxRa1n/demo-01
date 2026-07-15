extends WeaponBase

## 炮台（Minion·Turret）：环绕玩家的炮台，周期发射直射弹打最近敌人。
## 靠数量 / 射速 / 伤害成长。L5 发射 laser（近似为更高伤害）。

const Minion = preload("res://effects/minion.gd")

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "range": 360.0, "interval": 1.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "range": 360.0, "interval": 1.0},
	{"count": 2, "dmg": 1.2, "cd": 1.0, "range": 380.0, "interval": 0.95},
	{"count": 2, "dmg": 1.25, "cd": 1.0, "range": 380.0, "interval": 0.9},
	{"count": 3, "dmg": 1.35, "cd": 1.0, "range": 400.0, "interval": 0.85},
	{"count": 3, "dmg": 1.4, "cd": 1.0, "range": 400.0, "interval": 0.85},
	{"count": 4, "dmg": 1.4, "cd": 1.0, "range": 420.0, "interval": 0.8},
	{"count": 4, "dmg": 1.5, "cd": 1.0, "range": 440.0, "interval": 0.8},
]


func _init() -> void:
	weapon_id = &"turret"
	display_name = "炮台"
	weapon_icon_color = Color(0.5, 0.5, 0.6)
	base_damage = 8.0
	base_cooldown = 0.5  # 召唤物持续存在，_fire 仅幂等同步


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "炮台数量 / 射速 / 伤害"


func _fire() -> void:
	var lv := get_current_level_data()
	var dmg := _calc_damage(float(lv["dmg"]))
	_sync_minions(func(): return Minion.new(), int(lv["count"]), func(m, i, n):
		m.setup(72.0, 1.2, float(lv["range"]), float(lv["interval"]), 0.0, dmg, "ranged", Color(0.5, 0.5, 0.6), 14)
		m.set_base_angle(float(i) / float(n) * TAU)
	)
