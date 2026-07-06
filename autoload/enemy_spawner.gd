extends Node

## 生成配置
const MAX_ENEMIES: int = 320  # 同屏上限（原 200）
const SPAWN_MARGIN: float = 100.0  # 屏幕外额外距离
const SPAWN_EDGE_INSET: float = 50.0  # 生成点离地图墙边的最小距离
const DEFAULT_WARN: float = 0.6  # 普通敌人生成预警时长（秒）
const BOSS_WARN: float = 1.0  # Boss 生成预警时长（秒，给玩家更多反应时间）
const BURST_MAX_CAP: int = 12  # 单次成簇生成的敌人数量上限（原 8）

# ─── 敌人注册表 ────────────────────────────────────────────────────
# 每种敌人 = 一个独立场景 + 一个独立脚本（脚本里的 const CONFIG 是该敌人的单一数据源）。
#   KIND_SCENES ：实例化用（每种敌人一个 .tscn）
#   KIND_SCRIPTS：读 CONFIG 给「生成预警」用（颜色/尺寸，敌人尚未实例化）
# 想加新敌人：写 enemy_xxx.gd（extends EnemyBase + const CONFIG）+ enemy_xxx.tscn，
# 再在两张表各加一行即可，本文件其它逻辑（波次/burst/预警）全部不动。
const KIND_SCENES: Dictionary = {
	&"swarmer": preload("res://scenes/enemy_swarmer.tscn"),
	&"normal": preload("res://scenes/enemy_normal.tscn"),
	&"tank": preload("res://scenes/enemy_tank.tscn"),
	&"shooter": preload("res://scenes/enemy_shooter.tscn"),
	&"boss": preload("res://scenes/enemy_boss.tscn"),
}
const KIND_SCRIPTS: Dictionary = {
	&"swarmer": preload("res://scripts/enemy/enemy_swarmer.gd"),
	&"normal": preload("res://scripts/enemy/enemy_normal.gd"),
	&"tank": preload("res://scripts/enemy/enemy_tank.gd"),
	&"shooter": preload("res://scripts/enemy/enemy_shooter.gd"),
	&"boss": preload("res://scripts/enemy/enemy_boss.gd"),
}

# ─── 波次时间表（按已过分钟激活）──────────────────────────────────
# 字段：start_min 起激活；eligible/weights 加权随机选型；
#       rate_mult 乘到生成率；stat_scale 乘到 hp/伤害。
# 注意：boss 永不进 eligible，只由 BOSS_WAVES 强制生成。
const WAVES: Array = [
	{"start_min": 0.0, "eligible": [&"swarmer", &"normal"], "weights": [3, 2], "rate_mult": 1.0, "stat_scale": 1.0},
	{"start_min": 0.5, "eligible": [&"swarmer", &"normal"], "weights": [2, 3], "rate_mult": 1.4, "stat_scale": 1.0},
	{"start_min": 1.0, "eligible": [&"swarmer", &"normal", &"tank", &"shooter"], "weights": [2, 4, 1, 1], "rate_mult": 1.8, "stat_scale": 1.05},
	{"start_min": 1.5, "eligible": [&"normal", &"tank", &"shooter"], "weights": [3, 2, 1], "rate_mult": 2.3, "stat_scale": 1.15},
	{"start_min": 2.0, "eligible": [&"swarmer", &"normal", &"tank", &"shooter"], "weights": [3, 3, 2, 2], "rate_mult": 2.8, "stat_scale": 1.25},
	{"start_min": 2.5, "eligible": [&"swarmer", &"normal", &"tank", &"shooter"], "weights": [4, 3, 3, 2], "rate_mult": 3.4, "stat_scale": 1.4},
]

# ─── 一次性 Boss 波 ───────────────────────────────────────────────
# trigger_min(分钟) 到点触发一次：boss_count 个 boss + escort_kind×escort_count 护卫。
const BOSS_WAVES: Array = [
	{"trigger_min": 1.0, "boss_count": 1, "escort_kind": &"swarmer", "escort_count": 12},
	{"trigger_min": 2.0, "boss_count": 1, "escort_kind": &"normal", "escort_count": 10},
	{"trigger_min": 3.0, "boss_count": 2, "escort_kind": &"tank", "escort_count": 4},
]

## 生成状态
var spawn_accumulator: float = 0.0
var _fired_boss_waves: Dictionary = {}  # { 索引: true } 已触发的 Boss 波，防止重复

## 容器引用（重启后会陈旧，_process 里惰性重取）
var enemies_container: Node2D = null
var xp_gems_container: Node2D = null

## 场景引用
var xp_gem_scene: PackedScene
var spawn_warning_scene: PackedScene

## 预警特效容器（挂在 GameWorld 下与 Enemies 同级；重启后随场景重载，惰性重取）
var _warnings_container: Node2D = null


func _ready() -> void:
	xp_gem_scene = preload("res://effects/xp_gem.tscn")
	spawn_warning_scene = preload("res://effects/spawn_warning.tscn")
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

	# 按生成速率累加「生成配额」
	var rate := get_spawn_rate()
	spawn_accumulator += rate * delta

	# 配额足够时发起成簇 burst：每攒满 1 点配额触发一次，簇大小 1..burst_max 随机、
	# 位置成扇形簇拥，取代原来逐只零散生成，让敌群「一阵一阵」涌来且更有随机性。
	var burst_max := _current_burst_max()
	while spawn_accumulator >= 1.0 and enemies_container.get_child_count() < MAX_ENEMIES:
		# 簇大小 1..burst_max 随机，仅受同屏上限约束（不再用配额整数部分钳制，否则恒为 1）。
		# 配额按触发次数消耗，后期 burst_max 增大 → 单簇数量更多、敌群更密集。
		spawn_accumulator -= 1.0
		var want := randi_range(1, burst_max)
		want = mini(want, MAX_ENEMIES - enemies_container.get_child_count())
		if want > 0:
			_spawn_a_burst(want)


## 重置生成状态（由 game_over_controller 在重启时调用）
func reset() -> void:
	_fired_boss_waves.clear()
	spawn_accumulator = 0.0
	# 预警容器随场景重载而销毁，置空引用让下帧惰性重建
	_warnings_container = null


## 获取当前每秒生成速率（基础曲线 × 当前波次倍率）
func get_spawn_rate() -> float:
	# 基础曲线：每 15 秒 +1/s（原 20 秒），上限 14（原 10）→ 更早进入高频生成
	var base := minf(1.0 + game_manager.game_time / 15.0, 14.0)
	return base * float(_current_wave().get("rate_mult", 1.0))


## 当前每次 burst 的最大敌人数：随时间增长 + 波次倍率加成，封顶 BURST_MAX_CAP。
## 时间越往后、波次越激烈，单簇数量越大、随机性越强。
func _current_burst_max() -> int:
	var wave := _current_wave()
	var by_time := 1 + int(game_manager.game_time / 30.0)  # 每 30 秒 +1（原 45）→ 簇更早变大
	var by_wave := int(float(wave.get("rate_mult", 1.0)))  # rate_mult 高的波次簇更大
	return clampi(maxi(by_time, by_wave), 1, BURST_MAX_CAP)


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


## 成簇生成位置：以玩家为圆心，半径=屏幕半对角线+边距，
## 选一个随机锚点方向，簇内敌人在锚点 ±arc 扇形内分散，半径再抖动，避免完全重叠。
func _get_burst_positions(count: int) -> Array:
	var viewport_diag := get_viewport().get_visible_rect().size.length()
	var ring_radius := viewport_diag / 2.0 + SPAWN_MARGIN
	var center := game_manager.player.global_position
	var min_pos := Vector2(SPAWN_EDGE_INSET, SPAWN_EDGE_INSET)
	var max_pos := game_manager.MAP_SIZE - Vector2(SPAWN_EDGE_INSET, SPAWN_EDGE_INSET)

	var anchor := randf() * TAU          # 簇中心方向（整簇从一个方位涌来）
	var arc := deg_to_rad(35.0)          # 簇内 ±35° 扇形宽度
	var positions: Array = []
	for _i in count:
		var a := anchor + randf_range(-arc, arc)
		var r := ring_radius * randf_range(0.85, 1.1)  # 半径抖动
		var pos := (center + Vector2.from_angle(a) * r).clamp(min_pos, max_pos)
		positions.append(pos)
	return positions


## 公共生成逻辑：在指定位置生成指定类型敌人（受同屏上限约束）。
## config 不再传入：敌人自己的数值由其脚本 const CONFIG 提供，这里只传难度缩放。
func _spawn_at(kind: StringName, stat_scale: float, pos: Vector2) -> void:
	if enemies_container.get_child_count() >= MAX_ENEMIES:
		return
	var enemy: CharacterBody2D = KIND_SCENES[kind].instantiate()
	enemy.setup(stat_scale)  # 必须在 add_child 前调用，_ready 才能读到配置
	enemy.global_position = pos
	enemy.enemy_died.connect(_on_enemy_died)
	enemies_container.add_child(enemy)


## 发起一次成簇生成：在环形上选一组相邻位置，每个位置先播放预警，再生成敌人。
## 簇内每个敌人独立加权选型，类型也会混搭，进一步增加随机性。
func _spawn_a_burst(count: int) -> void:
	var stat_scale: float = _current_wave().get("stat_scale", 1.0)
	for pos in _get_burst_positions(count):
		var kind: StringName = _pick_archetype()
		_schedule_spawn(kind, KIND_SCRIPTS[kind].CONFIG, stat_scale, pos, DEFAULT_WARN)


## 预约一次生成：先在目标位置播放预警动画，动画结束时回调真正生成敌人。
## 敌人在预警期间尚不存在，玩家有时间躲开，避免凭空撞到。
func _schedule_spawn(kind: StringName, config: Dictionary, stat_scale: float, pos: Vector2, duration: float = DEFAULT_WARN) -> void:
	var container := _get_warnings_container()
	if container == null:
		return
	var warn: Node2D = spawn_warning_scene.instantiate()
	container.add_child(warn)
	warn.start(pos, kind, config, stat_scale, duration)
	warn.warning_finished.connect(_on_warning_finished)


## 预警容器：惰性获取/创建（挂在 GameWorld 下与 Enemies 同级）。
## 重启 reload_current_scene 后随 GameWorld 重建，靠 is_instance_valid 重取陈旧引用。
func _get_warnings_container() -> Node2D:
	if is_instance_valid(_warnings_container):
		return _warnings_container
	var gw := get_node_or_null("/root/Main/GameWorld")
	if gw:
		_warnings_container = gw.get_node_or_null("SpawnWarnings")
		if _warnings_container == null:
			_warnings_container = Node2D.new()
			_warnings_container.name = "SpawnWarnings"
			gw.add_child(_warnings_container)
	return _warnings_container


## 预警结束回调：在预警位置真正生成敌人（受同屏上限约束）
func _on_warning_finished(warn: Node2D) -> void:
	if not is_instance_valid(warn):
		return
	_spawn_at(warn.spawn_kind, warn.spawn_stat_scale, warn.global_position)


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


## 触发一次 Boss 波：boss 聚集在一个环形锚点附近，护卫分散在环形上。
## 与常规生成一样走预警动画（boss 预警更长），统一体验、避免凭空刷脸。
func _trigger_boss_wave(wave: Dictionary) -> void:
	var stat_scale: float = _current_wave().get("stat_scale", 1.0)
	var boss_count: int = wave.get("boss_count", 1)
	var escort_kind: StringName = wave.get("escort_kind", &"normal")
	var escort_count: int = wave.get("escort_count", 0)
	var anchor := get_spawn_position_ring()
	for _b in boss_count:
		var offset := Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		_schedule_spawn(&"boss", KIND_SCRIPTS[&"boss"].CONFIG, stat_scale, anchor + offset, BOSS_WARN)
	for _e in escort_count:
		_schedule_spawn(escort_kind, KIND_SCRIPTS[escort_kind].CONFIG, stat_scale, get_spawn_position_ring(), DEFAULT_WARN)


## 敌人死亡回调 → 按原型掉落多颗 XP 宝石
func _on_enemy_died(pos: Vector2, drop_count: int) -> void:
	if not xp_gems_container:
		return
	for i in drop_count:
		var gem: Area2D = xp_gem_scene.instantiate()
		gem.global_position = pos + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		xp_gems_container.call_deferred("add_child", gem)
