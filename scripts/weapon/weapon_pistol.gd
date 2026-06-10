extends Node

## 武器等级数据（来自策划文档）
const LEVEL_DATA: Array[Dictionary] = [
	{"projectiles": 1, "damage_mult": 1.0, "pierce": 0},  # Lv.1
	{"projectiles": 2, "damage_mult": 1.0, "pierce": 0},  # Lv.2
	{"projectiles": 2, "damage_mult": 1.1, "pierce": 0},  # Lv.3
	{"projectiles": 3, "damage_mult": 1.1, "pierce": 0},  # Lv.4
	{"projectiles": 3, "damage_mult": 1.2, "pierce": 1},  # Lv.5
	{"projectiles": 4, "damage_mult": 1.2, "pierce": 1},  # Lv.6
	{"projectiles": 4, "damage_mult": 1.3, "pierce": 1},  # Lv.7
	{"projectiles": 5, "damage_mult": 1.3, "pierce": 2},  # Lv.8
]

## 武器属性
var base_damage: float = 10.0
var base_cooldown: float = 1.0
var projectile_speed: float = 400.0
var weapon_level: int = 0  # 索引从 0 开始（对应 Lv.1）
var is_max_level: bool = false

## 内部
var cooldown_timer: float = 0.0

## 场景引用
var projectile_scene: PackedScene
var projectiles_container: Node2D


func _ready() -> void:
	projectile_scene = preload("res://scenes/projectile.tscn")
	await get_tree().process_frame
	projectiles_container = get_node("/root/Main/GameWorld/Projectiles")


func _process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not game_manager.player:
		return

	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		cooldown_timer = base_cooldown * game_manager.player.cooldown_mult
		_fire()


## 发射子弹
func _fire() -> void:
	var nearest_enemy := _find_nearest_enemy()
	if nearest_enemy == null:
		return

	var level_data: Dictionary = LEVEL_DATA[weapon_level]
	var num_proj: int = level_data["projectiles"]
	var dmg_mult: float = level_data["damage_mult"]
	var pierce: int = level_data["pierce"]

	# 计算基础方向（朝向最近敌人）
	var base_dir: Vector2 = (nearest_enemy.global_position - game_manager.player.global_position).normalized()

	# 发射多颗子弹，带扩散角度
	var spread_angle: float = 0.15  # ~8.6度
	var start_angle: float = -spread_angle * (num_proj - 1) / 2.0

	for i in num_proj:
		var angle_offset := start_angle + spread_angle * float(i)
		var dir := base_dir.rotated(angle_offset)

		var proj: Area2D = projectile_scene.instantiate()
		var total_damage: float = base_damage * float(dmg_mult) * game_manager.player.might
		proj.setup(total_damage, projectile_speed, dir, pierce)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)


## 查找最近的敌人
func _find_nearest_enemy() -> CharacterBody2D:
	if not enemy_spawner.enemies_container:
		return null

	var nearest: CharacterBody2D = null
	var nearest_dist: float = INF

	for child in enemy_spawner.enemies_container.get_children():
		if child is CharacterBody2D and is_instance_valid(child):
			var dist: float = child.global_position.distance_to(game_manager.player.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = child

	return nearest


## 升级武器（返回是否成功）
func level_up() -> bool:
	if is_max_level:
		return false
	weapon_level += 1
	if weapon_level >= LEVEL_DATA.size() - 1:
		is_max_level = true
	return true


## 获取当前武器等级显示名
func get_level_display() -> String:
	return "Pistol Lv.%d" % (weapon_level + 1)
