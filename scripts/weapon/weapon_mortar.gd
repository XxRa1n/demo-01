extends WeaponBase

## 矮人榴弹炮（LocatedBase·Lob）：大范围高伤爆炸 + 强击退，靠范围/伤害成长。
## L5「地震炮持续伤害+减速」留待后续，本批为大范围爆炸。

const projectile_scene: PackedScene = preload("res://scenes/explosive_projectile.tscn")
const MORTAR_SPEED: float = 300.0

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "blast": 100.0, "knockback": 260.0},
	{"dmg": 1.2, "cd": 1.0, "blast": 100.0, "knockback": 260.0},
	{"dmg": 1.2, "cd": 1.0, "blast": 115.0, "knockback": 280.0},
	{"dmg": 1.2, "cd": 0.9, "blast": 115.0, "knockback": 280.0},
	{"dmg": 1.5, "cd": 0.9, "blast": 130.0, "knockback": 320.0},   # 地震炮(大范围)
	{"dmg": 1.6, "cd": 0.9, "blast": 130.0, "knockback": 320.0},
	{"dmg": 1.6, "cd": 0.75, "blast": 140.0, "knockback": 340.0},
	{"dmg": 1.8, "cd": 0.75, "blast": 150.0, "knockback": 360.0},
]


func _init() -> void:
	weapon_id = &"mortar"
	display_name = "矮人榴弹炮"
	weapon_icon_color = Color(0.5, 0.5, 0.55)
	base_damage = 26.0
	base_cooldown = 1.8


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "爆炸范围 / 伤害 / 击退"


func _fire() -> void:
	var lv := get_current_level_data()
	_fire_lob(projectile_scene, MORTAR_SPEED, _calc_damage(float(lv["dmg"])), float(lv["blast"]), float(lv["knockback"]))
