extends WeaponBase

## 火箭炮：发射慢速火箭，命中或到达最大射程时爆炸，AoE 伤害 + 击退。

## 等级数据：damage_mult 爆炸伤害、blast_mult 爆炸半径、rockets 发射数
const LEVEL_DATA: Array = [
	{"damage_mult": 1.0, "blast_mult": 1.0, "rockets": 1},   # Lv.1
	{"damage_mult": 1.1, "blast_mult": 1.05, "rockets": 1},  # Lv.2
	{"damage_mult": 1.2, "blast_mult": 1.1, "rockets": 1},   # Lv.3
	{"damage_mult": 1.3, "blast_mult": 1.15, "rockets": 2},  # Lv.4
	{"damage_mult": 1.4, "blast_mult": 1.2, "rockets": 2},   # Lv.5
	{"damage_mult": 1.5, "blast_mult": 1.25, "rockets": 2},  # Lv.6
	{"damage_mult": 1.6, "blast_mult": 1.3, "rockets": 3},   # Lv.7
	{"damage_mult": 1.7, "blast_mult": 1.4, "rockets": 3},   # Lv.8
]

const ROCKET_SPEED: float = 320.0
const projectile_scene: PackedScene = preload("res://scenes/explosive_projectile.tscn")
const BASE_EXPLOSION_DMG: float = 30.0
const BASE_BLAST_RADIUS: float = 90.0
const KNOCKBACK_FORCE: float = 400.0


func _init() -> void:
	weapon_id = &"rocket"
	display_name = "火箭炮"
	weapon_icon_color = Color(0.9, 0.4, 0.4)
	base_damage = BASE_EXPLOSION_DMG
	base_cooldown = 1.6


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "更大爆炸 / 更高伤害 / 多发"


func _fire() -> void:
	var nearest_enemy := _find_nearest_enemy()
	if nearest_enemy == null:
		return

	var level_data: Dictionary = get_current_level_data()
	var dmg_mult: float = level_data["damage_mult"]
	var blast_mult: float = level_data["blast_mult"]
	var rockets: int = level_data["rockets"]

	var base_dir: Vector2 = (nearest_enemy.global_position - game_manager.player.global_position).normalized()
	var dmg: float = _calc_damage(dmg_mult)
	var blast: float = BASE_BLAST_RADIUS * blast_mult

	# 多发：小角度分散
	for i in rockets:
		var angle_offset := 0.0
		if rockets > 1:
			angle_offset = (float(i) / float(rockets - 1) - 0.5) * 0.25  # ±0.125 弧度
		var dir := base_dir.rotated(angle_offset)
		var proj = projectile_scene.instantiate()
		proj.setup(dmg, ROCKET_SPEED, dir, blast, KNOCKBACK_FORCE)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)
