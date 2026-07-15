extends WeaponBase

## 猫（Minion·Follower）：跟随玩家的快速近战，短间隔小 AoE。
## L5 分身10s（近似为更多数量）。

const Minion = preload("res://effects/minion.gd")

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "range": 150.0, "interval": 0.5, "radius": 36.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "range": 150.0, "interval": 0.5, "radius": 36.0},
	{"count": 2, "dmg": 1.2, "cd": 1.0, "range": 160.0, "interval": 0.5, "radius": 38.0},
	{"count": 2, "dmg": 1.25, "cd": 1.0, "range": 160.0, "interval": 0.45, "radius": 38.0},
	{"count": 3, "dmg": 1.3, "cd": 1.0, "range": 170.0, "interval": 0.45, "radius": 40.0},
	{"count": 3, "dmg": 1.35, "cd": 1.0, "range": 170.0, "interval": 0.45, "radius": 40.0},
	{"count": 4, "dmg": 1.35, "cd": 1.0, "range": 180.0, "interval": 0.4, "radius": 42.0},
	{"count": 4, "dmg": 1.45, "cd": 1.0, "range": 190.0, "interval": 0.4, "radius": 44.0},
]


func _init() -> void:
	weapon_id = &"cat"
	display_name = "猫"
	weapon_icon_color = Color(0.9, 0.7, 0.4)
	base_damage = 6.0
	base_cooldown = 0.5


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "数量 / 攻速 / 伤害"


func _fire() -> void:
	var lv := get_current_level_data()
	var dmg := _calc_damage(float(lv["dmg"]))
	_sync_minions(func(): return Minion.new(), int(lv["count"]), func(m, i, n):
		m.setup(58.0, 3.0, float(lv["range"]), float(lv["interval"]), float(lv["radius"]), dmg, "aoe", Color(0.9, 0.7, 0.4), 12, _gem_element())
		m.set_base_angle(float(i) / float(n) * TAU)
	)
