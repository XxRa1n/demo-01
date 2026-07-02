extends WeaponBase

## 霰弹枪：扇形多发，贴脸高爆发，远距离伤害衰减。
## 用 projectile_falloff（衰减弹丸）实现距离衰减；碰撞层与普通子弹一致（layer=4/mask=2）。

## 等级数据：pellets 弹丸数、damage_mult 伤害倍率、spread 总扩散角（弧度）
const LEVEL_DATA: Array = [
	{"pellets": 6, "damage_mult": 1.0, "spread": 0.45},   # Lv.1
	{"pellets": 7, "damage_mult": 1.05, "spread": 0.45},  # Lv.2
	{"pellets": 7, "damage_mult": 1.1, "spread": 0.42},   # Lv.3
	{"pellets": 8, "damage_mult": 1.15, "spread": 0.42},  # Lv.4
	{"pellets": 8, "damage_mult": 1.2, "spread": 0.40},   # Lv.5
	{"pellets": 9, "damage_mult": 1.25, "spread": 0.40},  # Lv.6
	{"pellets": 9, "damage_mult": 1.3, "spread": 0.38},   # Lv.7
	{"pellets": 10, "damage_mult": 1.35, "spread": 0.38}, # Lv.8
]

const SHOTGUN_SPEED: float = 600.0
const projectile_scene: PackedScene = preload("res://scenes/projectile_falloff.tscn")
const PER_PELLET_BASE: float = 4.0  # 单颗基础伤害（贴脸 Lv.1 = 6×4 = 24）
const FALLOFF_START: float = 250.0
const FALLOFF_END: float = 500.0
const MAX_RANGE: float = 520.0


func _init() -> void:
	weapon_id = &"shotgun"
	display_name = "霰弹枪"
	weapon_icon_color = Color(1.0, 0.5, 0.2)
	base_damage = PER_PELLET_BASE
	base_cooldown = 1.1


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "更多弹丸 / 伤害 / 更集中"


func _fire() -> void:
	var nearest_enemy := _find_nearest_enemy()
	if nearest_enemy == null:
		return

	var level_data: Dictionary = get_current_level_data()
	var pellets: int = level_data["pellets"]
	var dmg_mult: float = level_data["damage_mult"]
	var spread: float = level_data["spread"]  # 总扩散半角（弧度）

	var base_dir: Vector2 = (nearest_enemy.global_position - game_manager.player.global_position).normalized()
	var full_dmg: float = _calc_damage(dmg_mult)

	# 在 ±spread 范围内均匀分布 + 小抖动
	for i in pellets:
		var t: float = (float(i) / max(pellets - 1, 1)) - 0.5  # -0.5..0.5
		var angle_offset: float = t * spread * 2.0 + randf_range(-0.03, 0.03)
		var dir := base_dir.rotated(angle_offset)
		var proj = projectile_scene.instantiate()
		proj.setup(full_dmg, SHOTGUN_SPEED, dir, 0)  # pierce 0（击中即消失）
		proj.set_falloff(full_dmg, FALLOFF_START, FALLOFF_END, MAX_RANGE)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)
