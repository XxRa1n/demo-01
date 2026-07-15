extends WeaponBase

## 长剑（SlashArea）：朝最近敌人方向瞬时扇形斩击，命中范围内全部敌人 + 强击退。
## 靠范围/角度/伤害成长。L5 月光大剑波（近似为更大斩击）。

const Slash = preload("res://effects/slash.gd")

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "radius": 120.0, "arc": 1.75, "knockback": 300.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 120.0, "arc": 1.75, "knockback": 320.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 130.0, "arc": 1.9, "knockback": 320.0},
	{"dmg": 1.25, "cd": 0.9, "radius": 130.0, "arc": 1.9, "knockback": 340.0},
	{"dmg": 1.4, "cd": 0.9, "radius": 150.0, "arc": 2.1, "knockback": 360.0},   # 月光大剑波
	{"dmg": 1.45, "cd": 0.9, "radius": 150.0, "arc": 2.1, "knockback": 360.0},
	{"dmg": 1.45, "cd": 0.8, "radius": 160.0, "arc": 2.2, "knockback": 380.0},
	{"dmg": 1.55, "cd": 0.8, "radius": 170.0, "arc": 2.3, "knockback": 400.0},
]


func _init() -> void:
	weapon_id = &"sword"
	display_name = "长剑"
	weapon_icon_color = Color(0.9, 0.9, 0.95)
	base_damage = 14.0
	base_cooldown = 0.9


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "范围 / 角度 / 伤害"


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var lv := get_current_level_data()
	var s := Slash.new()
	s.setup(float(lv["radius"]), float(lv["arc"]), _calc_damage(float(lv["dmg"])), float(lv["knockback"]), facing)
	s.source_weapon = self
	s.global_position = game_manager.player.global_position
	projectiles_container.add_child(s)
