extends Area2D

## 回旋刀实体：绕玩家旋转的持续切割武器。
## 多刀均布（每把刀的 base_angle 由武器在创建时分配）。
## 用 get_overlapping_bodies 轮询命中 + per-enemy hit cooldown，防止单敌人被无限掉血。
## 碰撞层 layer=4/mask=2（与普通子弹一致，命中敌人）。

const HIT_CD: float = 0.33  # 每敌人命中冷却（约每秒 3 次）

var orbit_radius: float = 90.0
var orbit_speed: float = 3.5      # 角速度 rad/s
var base_angle: float = 0.0       # 多刀均布中的基础相位偏移
var angle: float = 0.0            # 当前累计旋转角
var damage_per_hit: float = 4.0
var _hit_cooldowns: Dictionary = {}  # { enemy_instance_id: 剩余cd }

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 占位纹理（银白色细长方块，刀刃感）
	var img := Image.create(10, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.92, 0.92, 0.95))
	sprite.texture = ImageTexture.create_from_image(img)


func set_params(p_radius: float, p_speed: float, p_base_angle: float, p_damage: float) -> void:
	orbit_radius = p_radius
	orbit_speed = p_speed
	base_angle = p_base_angle
	damage_per_hit = p_damage


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not is_instance_valid(game_manager.player):
		return

	# 绕玩家旋转（fmod 防止 angle 无限增长失精度）
	angle = fmod(angle + orbit_speed * delta, TAU)
	var current_angle := base_angle + angle
	global_position = game_manager.player.global_position + Vector2.from_angle(current_angle) * orbit_radius
	sprite.rotation = current_angle + PI * 0.5  # 刀刃朝向切线方向

	# 命中冷却倒计时 + 清理过期
	if not _hit_cooldowns.is_empty():
		var expired: Array = []
		for rid in _hit_cooldowns:
			_hit_cooldowns[rid] -= delta
			if _hit_cooldowns[rid] <= 0.0:
				expired.append(rid)
		for rid in expired:
			_hit_cooldowns.erase(rid)

	# 轮询当前接触的敌人
	for body in get_overlapping_bodies():
		if body is CharacterBody2D and body.has_method("take_damage") and not body.is_dead:
			var rid: int = body.get_instance_id()
			if not _hit_cooldowns.has(rid):
				body.take_damage(damage_per_hit)
				_hit_cooldowns[rid] = HIT_CD
