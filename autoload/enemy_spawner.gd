extends Node

## 生成配置
const MAX_ENEMIES: int = 200
const SPAWN_MARGIN: float = 100.0  # 屏幕外额外距离

## 生成状态
var spawn_accumulator: float = 0.0
var current_direction: int = 0  # 0=上, 1=右, 2=下, 3=左
var direction_counter: int = 0
var direction_batch: int = 3  # 每个方向连续生成几只

## 容器引用
var enemies_container: Node2D = null
var xp_gems_container: Node2D = null

## 场景引用
var enemy_scene: PackedScene
var xp_gem_scene: PackedScene


func _ready() -> void:
	enemy_scene = preload("res://scenes/enemy.tscn")
	xp_gem_scene = preload("res://effects/xp_gem.tscn")
	# 等待 main 场景准备好
	await get_tree().process_frame
	enemies_container = get_node("/root/Main/GameWorld/Enemies")
	xp_gems_container = get_node("/root/Main/GameWorld/XPGems")


func _process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not game_manager.player:
		return
	if not enemies_container:
		return

	# 清理超出范围的敌人
	_cleanup_distant_enemies()

	# 同屏上限检查
	if enemies_container.get_child_count() >= MAX_ENEMIES:
		return

	# 按生成速率累加
	var rate := get_spawn_rate()
	spawn_accumulator += rate * delta

	while spawn_accumulator >= 1.0 and enemies_container.get_child_count() < MAX_ENEMIES:
		spawn_accumulator -= 1.0
		_spawn_one_enemy()


## 获取当前每秒生成速率
func get_spawn_rate() -> float:
	var t := game_manager.game_time
	return min(1.0 + t / 20.0, 10.0)


## 获取当前时间下的敌人属性
func get_enemy_stats(t: float) -> Dictionary:
	return {
		"hp": 8.0 + t * 0.5,
		"speed": 60.0 + t * 0.3,
		"damage": int(5 + t * 0.1),
	}


## 生成一个敌人
func _spawn_one_enemy() -> void:
	var stats := get_enemy_stats(game_manager.game_time)
	var pos := get_spawn_position(current_direction)

	var enemy: CharacterBody2D = enemy_scene.instantiate()
	enemy.setup(stats["hp"], stats["speed"], stats["damage"])
	enemy.global_position = pos

	# 连接死亡信号（用于后续掉落 XP 宝石）
	enemy.enemy_died.connect(_on_enemy_died)

	enemies_container.add_child(enemy)

	# 方向轮换
	direction_counter += 1
	if direction_counter >= direction_batch:
		direction_counter = 0
		current_direction = (current_direction + 1) % 4


## 根据方向获取屏幕外生成位置
func get_spawn_position(direction: int) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var camera_pos := game_manager.player.global_position
	var half_w := viewport_size.x / 2.0
	var half_h := viewport_size.y / 2.0

	match direction:
		0:  # 上方
			return Vector2(
				camera_pos.x + randf_range(-half_w, half_w),
				camera_pos.y - half_h - SPAWN_MARGIN
			)
		1:  # 右方
			return Vector2(
				camera_pos.x + half_w + SPAWN_MARGIN,
				camera_pos.y + randf_range(-half_h, half_h)
			)
		2:  # 下方
			return Vector2(
				camera_pos.x + randf_range(-half_w, half_w),
				camera_pos.y + half_h + SPAWN_MARGIN
			)
		3:  # 左方
			return Vector2(
				camera_pos.x - half_w - SPAWN_MARGIN,
				camera_pos.y + randf_range(-half_h, half_h)
			)
		_:
			return camera_pos + Vector2(500, 0)


## 清理距离玩家过远的敌人
func _cleanup_distant_enemies() -> void:
	if not game_manager.player:
		return
	for child in enemies_container.get_children():
		if child.global_position.distance_to(game_manager.player.global_position) > 2000.0:
			child.queue_free()


## 敌人死亡回调 → 掉落 XP 宝石
func _on_enemy_died(pos: Vector2) -> void:
	if not xp_gems_container:
		return
	var gem: Area2D = xp_gem_scene.instantiate()
	gem.global_position = pos
	xp_gems_container.call_deferred("add_child", gem)
