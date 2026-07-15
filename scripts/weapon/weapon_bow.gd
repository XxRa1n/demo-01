extends WeaponBase

## 弓箭（ProjectileBase·Spread）：扇形多发箭矢，靠弹数与伤害成长。
## 8 级模板（宝石.md）：伤害 / 词条 / 攻速 / 万箭齐发 / 词条 / 减cd / 宝石槽。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

const ARROW_SPEED: float = 620.0
const SPREAD: float = 0.20  # ~11°

const LEVEL_DATA: Array = [
	{"count": 3, "dmg": 1.0, "cd": 1.0, "pierce": 0},   # Lv.1
	{"count": 3, "dmg": 1.15, "cd": 1.0, "pierce": 0},  # L2 +伤害
	{"count": 4, "dmg": 1.15, "cd": 1.0, "pierce": 0},  # L3 +词条(弹数)
	{"count": 4, "dmg": 1.15, "cd": 0.9, "pierce": 0},  # L4 +攻速
	{"count": 6, "dmg": 1.2, "cd": 0.9, "pierce": 0},   # L5 万箭齐发
	{"count": 6, "dmg": 1.3, "cd": 0.9, "pierce": 1},   # L6 +词条(穿透)
	{"count": 6, "dmg": 1.3, "cd": 0.8, "pierce": 1},   # L7 -cd
	{"count": 8, "dmg": 1.4, "cd": 0.8, "pierce": 1},   # L8 +宝石槽&词条
]


func _init() -> void:
	weapon_id = &"bow"
	display_name = "弓箭"
	weapon_icon_color = Color(0.6, 0.4, 0.2)
	base_damage = 7.0
	base_cooldown = 1.1


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "箭矢数量 / 伤害 / 穿透"


func _fire() -> void:
	var lv := get_current_level_data()
	_fire_seek_spread(projectile_scene, int(lv["count"]), SPREAD, ARROW_SPEED, _calc_damage(float(lv["dmg"])), int(lv["pierce"]))
