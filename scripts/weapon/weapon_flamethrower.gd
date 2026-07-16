extends WeaponBase

## 喷火（Shockwave·扇形 + 火）：朝最近敌人方向喷出火锥，附火元素（点燃）。
## L5「地上岩浆区域」留待后续；本批为火锥 + 燃烧附着。

const Shockwave = preload("res://effects/shockwave.gd")

const ARC: float = 1.4  # ~80° 火锥

const LEVEL_DATA: Array = [
	{"dmg": 1.0, "cd": 1.0, "radius": 170.0, "speed": 320.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 170.0, "speed": 320.0},
	{"dmg": 1.2, "cd": 1.0, "radius": 190.0, "speed": 330.0},
	{"dmg": 1.25, "cd": 0.85, "radius": 190.0, "speed": 340.0},
	{"dmg": 1.35, "cd": 0.85, "radius": 210.0, "speed": 350.0},   # 岩浆(近似为更大火锥)
	{"dmg": 1.4, "cd": 0.85, "radius": 210.0, "speed": 360.0},
	{"dmg": 1.4, "cd": 0.7, "radius": 230.0, "speed": 370.0},
	{"dmg": 1.5, "cd": 0.7, "radius": 250.0, "speed": 380.0},
]


func _init() -> void:
	weapon_id = &"flamethrower"
	display_name = "喷火"
	weapon_icon_color = Color(1.0, 0.5, 0.2)
	base_damage = 8.0
	base_cooldown = 1.1


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "范围 / 伤害 / 燃烧"


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var lv := get_current_level_data()
	var sw := Shockwave.new()
	sw.setup(float(lv["speed"]), float(lv["radius"]), _calc_damage(float(lv["dmg"])), 0.0, ARC, facing, DamageInfo.Element.FIRE, self)
	sw.global_position = game_manager.player.global_position
	projectiles_container.add_child(sw)
