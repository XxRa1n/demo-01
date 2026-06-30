extends CharacterBody2D

## 敌人原型标识（由 spawner 设置）
var kind: StringName = &"normal"

## 敌人属性（由 spawner 设置）
var enemy_hp: float = 8.0
var enemy_max_hp: float = 8.0
var enemy_speed: float = 60.0
var contact_damage: int = 5
var is_dead: bool = false

## 外观 / 碰撞（由 setup 写入，_ready 读取）
var color: Color = Color(0.85, 0.2, 0.2)
var sprite_size: int = 24
var collision_radius: float = 12.0
var damage_area_radius: float = 12.0

## 行为开关
var show_hp_bar: bool = false
var xp_drop: int = 1  # 死亡掉落的 XP 宝石数量

## 软分离（敌人间防重叠，boids 式排斥力）
const SEPARATION_WEIGHT: float = 1.0  # 推开强度系数（乘到速度上）
const SEPARATION_MAX_NEIGHBORS: int = 16  # 单次查询最多考虑的邻居数（控成本）
const SEPARATION_MAX_FORCE: float = 1.5  # 分离合力上限（保留大小信息、防超调抖动）
const STEER_SMOOTHING: float = 8.0  # 速度平滑系数（越大越跟手、越小越平滑）
var separation_radius: float = 24.0  # 开始排斥的距离（由原型配置）
var _sep_shape: CircleShape2D
var _sep_params: PhysicsShapeQueryParameters2D

## 信号
signal enemy_died(position: Vector2, xp_drop: int)

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea


func _ready() -> void:
	# 按配置尺寸+颜色生成占位纹理
	var img := Image.create(sprite_size, sprite_size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	sprite.texture = ImageTexture.create_from_image(img)

	# body 碰撞：新建独立 shape（enemy.tscn 里 body 与 DamageArea 共用同一子资源，
	# 不能原地改 radius，否则会把两者的碰撞范围耦合在一起）
	var body_shape := CircleShape2D.new()
	body_shape.radius = collision_radius
	$CollisionShape2D.shape = body_shape

	# 伤害区碰撞：同样新建独立 shape，半径可与 body 不同
	var dmg_shape := CircleShape2D.new()
	dmg_shape.radius = damage_area_radius
	damage_area.get_node("CollisionShape2D").shape = dmg_shape

	# 软分离查询：复用的圆形 shape + 参数（mask=2 仅查敌人层，排除自身）
	_sep_shape = CircleShape2D.new()
	_sep_shape.radius = separation_radius
	_sep_params = PhysicsShapeQueryParameters2D.new()
	_sep_params.shape = _sep_shape
	_sep_params.collision_mask = 2  # 敌人层
	_sep_params.exclude = [get_rid()]

	# 连接伤害区检测（碰到玩家 CharacterBody2D）
	damage_area.body_entered.connect(_on_damage_body_entered)

	queue_redraw()


## 由 spawner 调用：传入原型配置字典 + 时间难度缩放
func setup(p_kind: StringName, p_config: Dictionary, p_stat_scale: float = 1.0) -> void:
	kind = p_kind
	enemy_max_hp = p_config.get("hp", 8.0) * p_stat_scale
	enemy_hp = enemy_max_hp
	enemy_speed = p_config.get("speed", 60.0)  # 速度不缩放，保持放风筝手感
	contact_damage = int(round(p_config.get("damage", 5) * p_stat_scale))
	color = p_config.get("color", Color(0.85, 0.2, 0.2))
	sprite_size = p_config.get("sprite_size", 24)
	collision_radius = p_config.get("collision_radius", 12.0)
	damage_area_radius = p_config.get("damage_area_radius", 12.0)
	show_hp_bar = p_config.get("show_hp_bar", false)
	xp_drop = p_config.get("xp_drop", 1)
	separation_radius = p_config.get("separation_radius", float(sprite_size))


func _physics_process(delta: float) -> void:
	if is_dead or game_manager.game_over:
		return
	if not game_manager.player:
		return

	# 朝玩家方向移动
	var seek := (game_manager.player.global_position - global_position).normalized() * enemy_speed
	# 软分离：避开附近敌人，防止全部叠到玩家身上
	var avoid := _compute_separation() * enemy_speed * SEPARATION_WEIGHT
	var desired := seek + avoid
	# 限制最大速度，避免 seek+avoid 同向时超速
	if desired.length_squared() > enemy_speed * enemy_speed:
		desired = desired.normalized() * enemy_speed
	# 平滑插值到目标速度（帧率无关），消除帧间方向突变造成的抖动
	var t := 1.0 - exp(-STEER_SMOOTHING * delta)
	velocity = velocity.lerp(desired, t)
	move_and_slide()


## 软分离向量：远离 separation_radius 内的其它敌人。
## 用线性平滑衰减 (r-d)/r（而非 1/d），避免近距时力发散与帧间方向突变导致抖动；
## 保留合力大小（邻居多/近 → 推力大），最后限幅。
func _compute_separation() -> Vector2:
	if _sep_params == null:
		return Vector2.ZERO
	_sep_params.transform = global_transform
	var hits := get_world_2d().direct_space_state.intersect_shape(_sep_params, SEPARATION_MAX_NEIGHBORS)
	if hits.is_empty():
		return Vector2.ZERO
	var steer := Vector2.ZERO
	var r := separation_radius
	for hit in hits:
		var other: Node2D = hit["collider"]
		var diff := global_position - other.global_position
		var d := diff.length()
		if d <= 0.001:
			# 完全重叠：按实例 id 取稳定角度脱困，避免随机噪声抖动
			var stable_angle := float(get_instance_id() % 360) * (TAU / 360.0)
			steer += Vector2.from_angle(stable_angle)
			continue
		var strength := (r - d) / r  # 线性衰减：r 处为 0，越近越强，不会发散
		steer += diff.normalized() * strength
	# 限幅：保留大小信息但不超调
	if steer.length_squared() > SEPARATION_MAX_FORCE * SEPARATION_MAX_FORCE:
		steer = steer.normalized() * SEPARATION_MAX_FORCE
	return steer


## 血条：仅在 tank/boss 且 hp<max 时画在 sprite 上方
func _draw() -> void:
	if not show_hp_bar or is_dead or enemy_hp >= enemy_max_hp:
		return
	var bar_width := float(sprite_size) + 6.0
	var bar_height := 4.0
	var origin := Vector2(-bar_width / 2.0, -float(sprite_size) / 2.0 - 8.0)
	# 背景
	draw_rect(Rect2(origin, Vector2(bar_width, bar_height)), Color(0.0, 0.0, 0.0, 0.6), true)
	# 填充：满血偏绿、残血偏红
	var frac := clampf(enemy_hp / enemy_max_hp, 0.0, 1.0)
	var fill_color := Color(0.2, 0.8, 0.2).lerp(Color(0.85, 0.15, 0.15), 1.0 - frac)
	draw_rect(Rect2(origin, Vector2(bar_width * frac, bar_height)), fill_color, true)


func take_damage(amount: float) -> void:
	# 死亡保护：敌人已被击杀但尚未 queue_free（帧末才销毁）期间，
	# 避免多颗子弹重复触发击杀计数与宝石掉落。
	if is_dead:
		return
	enemy_hp -= amount
	queue_redraw()  # 刷新血条
	if enemy_hp <= 0.0:
		is_dead = true
		enemy_died.emit(global_position, xp_drop)
		game_manager.add_kill()
		call_deferred("queue_free")


func _on_damage_body_entered(body: Node2D) -> void:
	# 如果碰到玩家，对玩家造成伤害
	if body == game_manager.player:
		if game_manager.player:
			game_manager.player.take_damage(contact_damage)
