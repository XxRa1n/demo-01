extends WeaponBase

## 回旋镖（ProjectileBase·Seek，回旋为后续精修）：高速穿透飞镖，靠弹数与穿透成长。
## 完整「飞出后折返」行为留待后续用独立 ReturningProjectile 实体实现。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const BOOMERANG_SPEED: float = 520.0

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "pierce": 2},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "pierce": 2},
	{"count": 2, "dmg": 1.2, "cd": 1.0, "pierce": 2},
	{"count": 2, "dmg": 1.2, "cd": 0.85, "pierce": 3},
	{"count": 3, "dmg": 1.3, "cd": 0.85, "pierce": 4},   # 黄金回旋(多弹多穿)
	{"count": 3, "dmg": 1.4, "cd": 0.85, "pierce": 4},
	{"count": 3, "dmg": 1.4, "cd": 0.7, "pierce": 5},
	{"count": 4, "dmg": 1.5, "cd": 0.7, "pierce": 6},
]


func _init() -> void:
	weapon_id = &"boomerang"
	display_name = "回旋镖"
	weapon_icon_color = Color(0.95, 0.75, 0.2)
	base_damage = 9.0
	base_cooldown = 1.2


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "弹数 / 穿透 / 冷却"


func _fire() -> void:
	var lv := get_current_level_data()
	_fire_seek_spread(projectile_scene, int(lv["count"]), 0.25, BOOMERANG_SPEED, _calc_damage(float(lv["dmg"])), int(lv["pierce"]))
