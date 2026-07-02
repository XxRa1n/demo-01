extends WeaponBase

## 手枪（基准武器）：稳定单发，瞄准最近敌人，靠弹数/伤害/穿透成长。
## _process 计时、找敌、伤害计算都继承自 WeaponBase，这里只定义等级数据与 _fire。

## 等级数据（来自策划文档）
const LEVEL_DATA: Array = [
	{"projectiles": 1, "damage_mult": 1.0, "pierce": 0},  # Lv.1
	{"projectiles": 2, "damage_mult": 1.0, "pierce": 0},  # Lv.2
	{"projectiles": 2, "damage_mult": 1.1, "pierce": 0},  # Lv.3
	{"projectiles": 3, "damage_mult": 1.1, "pierce": 0},  # Lv.4
	{"projectiles": 3, "damage_mult": 1.2, "pierce": 1},  # Lv.5
	{"projectiles": 4, "damage_mult": 1.2, "pierce": 1},  # Lv.6
	{"projectiles": 4, "damage_mult": 1.3, "pierce": 1},  # Lv.7
	{"projectiles": 5, "damage_mult": 1.3, "pierce": 2},  # Lv.8
]

const PISTOL_SPEED: float = 700.0  # 玩家子弹快速
const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")


func _init() -> void:
	weapon_id = &"pistol"
	display_name = "手枪"
	weapon_icon_color = Color(1.0, 0.9, 0.2)
	base_damage = 10.0
	base_cooldown = 1.0


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "更多子弹 / 伤害 / 穿透"


func _fire() -> void:
	var nearest_enemy := _find_nearest_enemy()
	if nearest_enemy == null:
		return

	var level_data: Dictionary = get_current_level_data()
	var num_proj: int = level_data["projectiles"]
	var dmg_mult: float = level_data["damage_mult"]
	var pierce: int = level_data["pierce"]

	# 基础方向朝向最近敌人
	var base_dir: Vector2 = (nearest_enemy.global_position - game_manager.player.global_position).normalized()

	# 多颗子弹带小扩散
	var spread_angle: float = 0.15  # ~8.6°
	var start_angle: float = -spread_angle * (num_proj - 1) / 2.0
	for i in num_proj:
		var angle_offset := start_angle + spread_angle * float(i)
		var dir := base_dir.rotated(angle_offset)
		var proj: Area2D = projectile_scene.instantiate()
		proj.setup(_calc_damage(dmg_mult), PISTOL_SPEED, dir, pierce)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)
