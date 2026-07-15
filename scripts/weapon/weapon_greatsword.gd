extends WeaponBase

## 巨剑（SlashArea）：更宽更大的斩击，高伤慢速。
## L5 巨剑变大5s（近似为更大范围/角度）。

const Slash = preload("res://effects/slash.gd")

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "radius": 140.0, "arc": 2.2, "knockback": 360.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 140.0, "arc": 2.2, "knockback": 380.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 150.0, "arc": 2.3, "knockback": 380.0},
	{"dmg": 1.25, "cd": 1.0, "radius": 150.0, "arc": 2.3, "knockback": 400.0},
	{"dmg": 1.45, "cd": 1.0, "radius": 175.0, "arc": 2.5, "knockback": 440.0},   # 巨剑变大
	{"dmg": 1.5, "cd": 1.0, "radius": 175.0, "arc": 2.5, "knockback": 440.0},
	{"dmg": 1.5, "cd": 0.9, "radius": 185.0, "arc": 2.6, "knockback": 460.0},
	{"dmg": 1.6, "cd": 0.9, "radius": 195.0, "arc": 2.7, "knockback": 480.0},
]


func _init() -> void:
	weapon_id = &"greatsword"
	display_name = "巨剑"
	weapon_icon_color = Color(0.7, 0.7, 0.8)
	base_damage = 20.0
	base_cooldown = 1.3


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "范围 / 伤害 / 击退"


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var lv := get_current_level_data()
	var s := Slash.new()
	s.setup(float(lv["radius"]), float(lv["arc"]), _calc_damage(float(lv["dmg"])), float(lv["knockback"]), facing)
	s.source_weapon = self
	s.global_position = game_manager.player.global_position
	projectiles_container.add_child(s)
