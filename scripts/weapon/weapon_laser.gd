extends WeaponBase

## 激光（Beam）：锁定最近敌人方向、持续按帧 DPS 的光束，靠宽度/伤害/光束数成长。
## L5「发射 X 型光线」留待后续；本批为单束持续激光。

const Beam = preload("res://effects/beam.gd")

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "width": 14.0, "length": 520.0, "active": 1.0},
	{"dmg": 1.15, "cd": 1.0, "width": 16.0, "length": 520.0, "active": 1.0},
	{"dmg": 1.15, "cd": 1.0, "width": 18.0, "length": 540.0, "active": 1.0},
	{"dmg": 1.2, "cd": 0.9, "width": 18.0, "length": 540.0, "active": 1.1},
	{"dmg": 1.3, "cd": 0.9, "width": 20.0, "length": 560.0, "active": 1.2},   # X型(近似加宽)
	{"dmg": 1.4, "cd": 0.9, "width": 22.0, "length": 580.0, "active": 1.2},
	{"dmg": 1.4, "cd": 0.8, "width": 22.0, "length": 600.0, "active": 1.2},
	{"dmg": 1.5, "cd": 0.8, "width": 24.0, "length": 620.0, "active": 1.3},
]


func _init() -> void:
	weapon_id = &"laser"
	display_name = "激光"
	weapon_icon_color = Color(0.4, 0.8, 1.0)
	base_damage = 12.0
	base_cooldown = 1.5


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "光束宽度 / 伤害 / 持续"


func _fire() -> void:
	var lv := get_current_level_data()
	var beam := Beam.new()
	# DPS 取伤害的 3 倍（持续光束），active 期内总伤 ≈ base×mult×3
	beam.setup(_calc_damage(float(lv["dmg"])) * 3.0, float(lv["length"]), float(lv["width"]), float(lv["active"]), _gem_element(), self)
	beam.global_position = game_manager.player.global_position
	projectiles_container.add_child(beam)
