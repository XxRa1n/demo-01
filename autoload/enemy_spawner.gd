extends Node

## 生成配置
const MAX_ENEMIES: int = 200
const SPAWN_MARGIN: float = 100.0  # 屏幕外额外距离
const SPAWN_EDGE_INSET: float = 50.0  # 生成点离地图墙边的最小距离

# ─── 敌人原型 ──────────────────────────────────────────────────────
# 字段：hp, speed, damage, color, sprite_size, collision_radius,
#       damage_area_radius, xp_drop, show_hp_bar, separation_radius
const ARCHETYPES: Dictionary = {
	&"swarmer": {
		"hp": 3.0, "speed": 110.0, "damage": 3,
		"color": Color(0.9, 0.5, 0.2), "sprite_size": 14,
		"collision_radius": 7.0, "damage_area_radius": 8.0,
		"xp_drop": 1, "show_hp_bar": false, "separation_radius": 18.0,
	},
	&"normal": {
		"hp": 10.0, "speed": 60.0, "damage": 6,
		"color": Color(0.85, 0.2, 0.2), "sprite_size": 24,
		"collision_radius": 12.0, "damage_area_radius": 12.0,
		"xp_drop": 1, "show_hp_bar": false, "separation_radius": 28.0,
	},
	&"tank": {
		"hp": 55.0, "speed": 35.0, "damage": 12,
		"color": Color(0.35, 0.35, 0.45), "sprite_size": 40,
		"collision_radius": 20.0, "damage_area_radius": 22.0,
		"xp_drop": 5, "show_hp_bar": true, "separation_radius": 44.0,
	},
	&"boss": {
		"hp": 600.0, "speed": 28.0, "damage": 25,
		"color": Color(0.55, 0.1, 0.7), "sprite_size": 72,
		"collision_radius": 38.0, "damage_area_radius": 42.0,
		"xp_drop": 50, "show_hp_bar": true, "separation_radius": 80.0,
	},
}

# ─── 波次时间表（按已过分钟激活）──────────────────────────────────
# 字段：start_min 起激活；eligible/weights 加权随机选型；
#       rate_mult 乘到生成率；stat_scale 乘到 hp/伤害。
# 注意：boss 永不进 eligible，只由 BOSS_WAVES 强制生成。
const WAVES: Array = [
	{"start_min": 0.0, "eligible": [&"swarmer", &"normal"], "weights": [3, 2], "rate_mult": 0.8, "stat_scale": 1.0},
	{"start_min": 1.0, "eligible": [&"swarmer", &"normal"], "weights": [2, 3], "rate_mult": 1.0, "stat_scale": 1.0},
	{"start_min": 3.0, "eligible": [&"swarmer", &"normal", &"tank"], "weights": [2, 4, 1], "rate_mult": 1.2, "stat_scale": 1.1},
	{"start_min": 5.0, "eligible": [&"normal", &"tank"], "weights": [3, 2], "rate_mult": 1.5, "stat_scale": 1.3},
	{"start_min": 7.0, "eligible": [&"swarmer", &"normal", &"tank"], "weights": [3, 3, 2], "rate_mult": 1.8, "stat_scale": 1.6},
	{"start_min": 9.0, "eligible": [&"swarmer", &"normal", &"tank"], "weights": [4, 3, 3], "rate_mult": 2.2, "stat_scale": 2.0},
]

# ─── 一次性 Boss 波 ───────────────────────────────────────────────
# trigger_min(分钟) 到点触发一次：boss_count 个 boss + escort_kind×escort_count 护卫。
const BOSS_WAVES: Array = [
	{"trigger_min": 3.0, "boss_count": 1, "escort_kind": &"swarmer", "escort_count": 12},
	{"trigger_min": 5.0, "boss_count": 1, "escort_kind": &"normal", "escort_count": 10},
	{"trigger_min": 8.0, "boss_count": 2, "escort_kind": &"tank", "escort_count": 4},
]

## 生成状态
var spawn_accumulator: float = 0.0
var _fired_boss_waves: Dictionary = {}  # { 索引: true } 已触发的 Boss 波，防止重复

## 容器引用（重启后会陈旧，_process 里惰性重取）
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
	enemies_container = get_node_or_null("/root/Main/GameWorld/Enemies")
	xp_gems_container = get_node_or_null("/root/Main/GameWorld/XPGems")


func _process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not game_manager.player:
		return

	# 容器引用可能因场景重载而陈旧，惰性重取
	if not is_instance_valid(enemies_container):
		enemies_container = get_node_or_null("/root/Main/GameWorld/Enemies")
	if not is_instance_valid(xp_gems_container):
		xp_gems_container = get_node_or_null("/root/Main/GameWorld/XPGems")
	if not enemies_container:
		return

	# 定时 Boss 波（独立于同屏上限的常规生成）
	_update_boss_waves()

	# 同屏上限检查
	if enemies_container.get_child_count() >= MAX_ENEMIES:
		return

	# 按生成速率累加
	var rate := get_spawn_rate()
	spawn_accumulator += rate * delta

	while spawn_accumulator >= 1.0 and enemies_container.get_child_count() < MAX_ENEMIES:
		spawn_accumulator -= 1.0
		_spawn_one_enemy()


## 重置生成状态（由 game_over_controller 在重启时调用）
func reset() -> void:
	_fired_boss_waves.clear()
	spawn_accumulator = 0.0


## 获取当前每秒生成速率（基础曲线 × 当前波次倍率）
func get_spawn_rate() -> float:
	var base := minf(1.0 + game_manager.game_time / 20.0, 10.0)
	return base * float(_current_wave().get("rate_mult", 1.0))


## 返回当前激活的波次（start_min ≤ 已过分钟 的最后一条）
func _current_wave() -> Dictionary:
	var minutes := game_manager.game_time / 60.0
	var active: Dictionary = WAVES[0]
	for w in WAVES:
		if minutes >= w["start_min"]:
			active = w
	return active


## 加权随机选一个原型（永远不返回 boss）
func _pick_archetype() -> StringName:
	var wave := _current_wave()
	var kinds: Array = wave["eligible"]
	var weights: Array = wave["weights"]
	var total := 0
	for w in weights:
		total += w
	var roll := randi() % total
	var acc := 0
	for i in kinds.size():
		acc += weights[i]
		if roll < acc:
			return kinds[i]
	return kinds[kinds.size() - 1]  # 兜底


## 环形生成位置：以玩家为圆心，半径=屏幕半对角线+边距（保证整圈在屏外），
## 随机角度取点，校验是否落在地图内；最多试 8 次；兜底 clamp。
func get_spawn_position_ring() -> Vector2:
	var viewport_diag := get_viewport().get_visible_rect().size.length()
	var ring_radius := viewport_diag / 2.0 + SPAWN_MARGIN
	var center := game_manager.player.global_position
	var min_pos := Vector2(SPAWN_EDGE_INSET, SPAWN_EDGE_INSET)
	var max_pos := game_manager.MAP_SIZE - Vector2(SPAWN_EDGE_INSET, SPAWN_EDGE_INSET)

	for i in 8:
		var pos := center + Vector2.from_angle(randf() * TAU) * ring_radius
		if pos.clamp(min_pos, max_pos) == pos:  # 未越界
			return pos
	# 玩家被逼到角落、整圈都没合法点时，clamp 兜底
	return (center + Vector2.from_angle(randf() * TAU) * ring_radius).clamp(min_pos, max_pos)


## 公共生成逻辑：在指定位置生成指定原型敌人（受同屏上限约束）
func _spawn_at(kind: StringName, config: Dictionary, stat_scale: float, pos: Vector2) -> void:
	if enemies_container.get_child_count() >= MAX_ENEMIES:
		return
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	enemy.setup(kind, config, stat_scale)  # 必须在 add_child 前调用，_ready 才能读到配置
	enemy.global_position = pos
	enemy.enemy_died.connect(_on_enemy_died)
	enemies_container.add_child(enemy)


## 常规生成一只：按当前波次加权选型
func _spawn_one_enemy() -> void:
	var kind: StringName = _pick_archetype()
	_spawn_at(kind, ARCHETYPES[kind], _current_wave().get("stat_scale", 1.0), get_spawn_position_ring())


## 每帧检查并触发到点的 Boss 波（每条只触发一次）
func _update_boss_waves() -> void:
	if not xp_gems_container:
		return
	var minutes := game_manager.game_time / 60.0
	for i in BOSS_WAVES.size():
		if _fired_boss_waves.has(i):
			continue
		if minutes >= BOSS_WAVES[i]["trigger_min"]:
			_fired_boss_waves[i] = true
			_trigger_boss_wave(BOSS_WAVES[i])


## 触发一次 Boss 波：boss 聚集在一个环形锚点附近，护卫分散在环形上
func _trigger_boss_wave(wave: Dictionary) -> void:
	var stat_scale: float = _current_wave().get("stat_scale", 1.0)
	var boss_count: int = wave.get("boss_count", 1)
	var escort_kind: StringName = wave.get("escort_kind", &"normal")
	var escort_count: int = wave.get("escort_count", 0)
	var anchor := get_spawn_position_ring()
	for _b in boss_count:
		_spawn_at(&"boss", ARCHETYPES[&"boss"], stat_scale,
				anchor + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0)))
	for _e in escort_count:
		_spawn_at(escort_kind, ARCHETYPES[escort_kind], stat_scale, get_spawn_position_ring())


## 敌人死亡回调 → 按原型掉落多颗 XP 宝石
func _on_enemy_died(pos: Vector2, drop_count: int) -> void:
	if not xp_gems_container:
		return
	for i in drop_count:
		var gem: Area2D = xp_gem_scene.instantiate()
		gem.global_position = pos + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		xp_gems_container.call_deferred("add_child", gem)
