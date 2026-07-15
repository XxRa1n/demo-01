extends WeaponBase

## 宝石法术（ProjectileBase·Spread）：大扇形多发弹幕，靠弹数成长。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const SPELL_SPEED: float = 540.0
const SPREAD: float = 0.55  # 大扇形

const LEVEL_DATA: Array = [
	{"count": 5, "dmg": 1.0, "cd": 1.0, "pierce": 0},
	{"count": 5, "dmg": 1.15, "cd": 1.0, "pierce": 0},
	{"count": 6, "dmg": 1.15, "cd": 1.0, "pierce": 0},
	{"count": 6, "dmg": 1.15, "cd": 0.9, "pierce": 0},
	{"count": 8, "dmg": 1.25, "cd": 0.9, "pierce": 0},
	{"count": 8, "dmg": 1.3, "cd": 0.9, "pierce": 1},
	{"count": 8, "dmg": 1.3, "cd": 0.75, "pierce": 1},
	{"count": 10, "dmg": 1.4, "cd": 0.75, "pierce": 1},
]


func _init() -> void:
	weapon_id = &"gem_spell"
	display_name = "宝石法术"
	weapon_icon_color = Color(0.6, 0.85, 1.0)
	base_damage = 5.0
	base_cooldown = 1.2


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "弹幕数量 / 伤害 / 冷却"


func _fire() -> void:
	var lv := get_current_level_data()
	_fire_seek_spread(projectile_scene, int(lv["count"]), SPREAD, SPELL_SPEED, _calc_damage(float(lv["dmg"])), int(lv["pierce"]))
