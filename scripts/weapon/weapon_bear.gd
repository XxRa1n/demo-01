extends WeaponBase

## 熊（Minion·Follower）：跟随玩家的重型 AoE，大范围高伤慢速。
## L5 横冲直撞（近似为更大范围 + 更多数量）。

const Minion = preload("res://effects/minion.gd")

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "range": 150.0, "interval": 1.4, "radius": 70.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "range": 150.0, "interval": 1.4, "radius": 70.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "range": 160.0, "interval": 1.3, "radius": 76.0},
	{"count": 1, "dmg": 1.3, "cd": 1.0, "range": 160.0, "interval": 1.2, "radius": 76.0},
	{"count": 2, "dmg": 1.4, "cd": 1.0, "range": 175.0, "interval": 1.1, "radius": 84.0},
	{"count": 2, "dmg": 1.45, "cd": 1.0, "range": 175.0, "interval": 1.1, "radius": 84.0},
	{"count": 2, "dmg": 1.45, "cd": 1.0, "range": 185.0, "interval": 1.0, "radius": 90.0},
	{"count": 3, "dmg": 1.55, "cd": 1.0, "range": 195.0, "interval": 1.0, "radius": 96.0},
]


func _init() -> void:
	weapon_id = &"bear"
	display_name = "熊"
	weapon_icon_color = Color(0.5, 0.4, 0.3)
	base_damage = 16.0
	base_cooldown = 0.5


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "范围 / 伤害 / 数量"


func _fire() -> void:
	var lv := get_current_level_data()
	var dmg := _calc_damage(float(lv["dmg"]))
	_sync_minions(func(): return Minion.new(), int(lv["count"]), func(m, i, n):
		m.setup(80.0, 1.6, float(lv["range"]), float(lv["interval"]), float(lv["radius"]), dmg, "aoe", Color(0.5, 0.4, 0.3), 22, _gem_element())
		m.set_base_angle(float(i) / float(n) * TAU)
	)
