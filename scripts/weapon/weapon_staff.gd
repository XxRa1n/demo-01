extends WeaponBase

## 棍子（SlashArea）：较窄但快的斩击，靠攻速/伤害成长。
## L5「投掷棍子原地旋转造伤减速」留待后续；本批为快速窄斩。

const Slash = preload("res://effects/slash.gd")

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "radius": 130.0, "arc": 1.4, "knockback": 220.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 130.0, "arc": 1.4, "knockback": 240.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 138.0, "arc": 1.5, "knockback": 240.0},
	{"dmg": 1.25, "cd": 0.8, "radius": 138.0, "arc": 1.5, "knockback": 260.0},
	{"dmg": 1.4, "cd": 0.8, "radius": 150.0, "arc": 1.6, "knockback": 280.0},   # 投掷旋转(近似)
	{"dmg": 1.45, "cd": 0.8, "radius": 150.0, "arc": 1.6, "knockback": 280.0},
	{"dmg": 1.45, "cd": 0.65, "radius": 158.0, "arc": 1.7, "knockback": 300.0},
	{"dmg": 1.55, "cd": 0.65, "radius": 168.0, "arc": 1.8, "knockback": 320.0},
]


func _init() -> void:
	weapon_id = &"staff"
	display_name = "棍子"
	weapon_icon_color = Color(0.75, 0.55, 0.3)
	base_damage = 12.0
	base_cooldown = 0.8


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "攻速 / 范围 / 伤害"


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var lv := get_current_level_data()
	var s := Slash.new()
	s.setup(float(lv["radius"]), float(lv["arc"]), _calc_damage(float(lv["dmg"])), float(lv["knockback"]), facing)
	s.source_weapon = self
	s.global_position = game_manager.player.global_position
	projectiles_container.add_child(s)
