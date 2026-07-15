extends WeaponBase

## 声波（Shockwave·Pulse）：从玩家发出 360° 扩散环，扫到的敌人受伤害 + 击退。
## 靠波数 / 半径 / 伤害成长。

const Shockwave = preload("res://effects/shockwave.gd")

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "radius": 200.0, "speed": 280.0, "knockback": 180.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 200.0, "speed": 280.0, "knockback": 200.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 230.0, "speed": 290.0, "knockback": 200.0},
	{"dmg": 1.25, "cd": 0.9, "radius": 230.0, "speed": 300.0, "knockback": 220.0},
	{"dmg": 1.35, "cd": 0.9, "radius": 260.0, "speed": 310.0, "knockback": 240.0},   # 共振(范围+击退)
	{"dmg": 1.4, "cd": 0.9, "radius": 260.0, "speed": 320.0, "knockback": 240.0},
	{"dmg": 1.4, "cd": 0.8, "radius": 290.0, "speed": 330.0, "knockback": 260.0},
	{"dmg": 1.5, "cd": 0.8, "radius": 320.0, "speed": 340.0, "knockback": 280.0},
]


func _init() -> void:
	weapon_id = &"sonic"
	display_name = "声波"
	weapon_icon_color = Color(0.8, 0.9, 1.0)
	base_damage = 10.0
	base_cooldown = 1.2


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "范围 / 伤害 / 击退"


func _fire() -> void:
	var lv := get_current_level_data()
	var sw := Shockwave.new()
	sw.setup(float(lv["speed"]), float(lv["radius"]), _calc_damage(float(lv["dmg"])), float(lv["knockback"]))
	sw.element = _gem_element()
	sw.source_weapon = self
	sw.global_position = game_manager.player.global_position
	projectiles_container.add_child(sw)
