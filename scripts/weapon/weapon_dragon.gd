extends WeaponBase

## 龙（Minion·Follower）：跟随玩家的中距吐息 AoE，附火元素（点燃）。
## L5 三条火焰路径（近似为更大 AoE + 更多数量）。

const DamageInfo = preload("res://scripts/combat/damage_info.gd")
const Minion = preload("res://effects/minion.gd")

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "range": 170.0, "interval": 1.0, "radius": 52.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "range": 170.0, "interval": 1.0, "radius": 52.0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "range": 180.0, "interval": 0.95, "radius": 56.0},
	{"count": 1, "dmg": 1.25, "cd": 1.0, "range": 180.0, "interval": 0.9, "radius": 56.0},
	{"count": 2, "dmg": 1.35, "cd": 1.0, "range": 195.0, "interval": 0.85, "radius": 62.0},
	{"count": 2, "dmg": 1.4, "cd": 1.0, "range": 195.0, "interval": 0.85, "radius": 62.0},
	{"count": 3, "dmg": 1.4, "cd": 1.0, "range": 205.0, "interval": 0.8, "radius": 66.0},
	{"count": 3, "dmg": 1.5, "cd": 1.0, "range": 215.0, "interval": 0.8, "radius": 70.0},
]


func _init() -> void:
	weapon_id = &"dragon"
	display_name = "龙"
	weapon_icon_color = Color(0.95, 0.4, 0.3)
	base_damage = 14.0
	base_cooldown = 0.5


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "数量 / 范围 / 燃烧"


func _fire() -> void:
	var lv := get_current_level_data()
	var dmg := _calc_damage(float(lv["dmg"]))
	_sync_minions(func(): return Minion.new(), int(lv["count"]), func(m, i, n):
		m.setup(66.0, 2.2, float(lv["range"]), float(lv["interval"]), float(lv["radius"]), dmg, "aoe", Color(0.95, 0.4, 0.3), 18, _gem_element(DamageInfo.Element.FIRE))
		m.set_base_angle(float(i) / float(n) * TAU)
	)
