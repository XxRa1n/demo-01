extends WeaponBase

## 竖琴（ProjectileBase·特殊）：随机方向发射「音符」子弹（do/re/mi），靠弹数成长。
## L5「集齐 do re mi 圆形范围伤害」留待后续；本批为随机散射。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const NOTE_SPEED: float = 560.0

const LEVEL_DATA: Array = [
	{"count": 1, "dmg": 1.0, "cd": 1.0, "pierce": 0},
	{"count": 1, "dmg": 1.2, "cd": 1.0, "pierce": 0},
	{"count": 2, "dmg": 1.2, "cd": 1.0, "pierce": 0},
	{"count": 2, "dmg": 1.2, "cd": 0.8, "pierce": 0},
	{"count": 3, "dmg": 1.3, "cd": 0.8, "pierce": 0},
	{"count": 3, "dmg": 1.4, "cd": 0.8, "pierce": 1},
	{"count": 3, "dmg": 1.4, "cd": 0.65, "pierce": 1},
	{"count": 4, "dmg": 1.5, "cd": 0.65, "pierce": 1},
]


func _init() -> void:
	weapon_id = &"harp"
	display_name = "竖琴"
	weapon_icon_color = Color(0.95, 0.6, 0.9)
	base_damage = 9.0
	base_cooldown = 1.0


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "音符数量 / 伤害 / 冷却"


func _fire() -> void:
	var lv := get_current_level_data()
	var n := int(lv["count"])
	var dmg := _calc_damage(float(lv["dmg"]))
	var pierce := int(lv["pierce"])
	for _i in n:
		var dir := Vector2.from_angle(randf() * TAU)
		var proj := projectile_scene.instantiate()
		proj.setup(dmg, NOTE_SPEED, dir, pierce)
		proj.source_weapon = self
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)
