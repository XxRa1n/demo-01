extends Area2D

## 敌人发射的子弹：大而慢，碰到玩家造成伤害。
## 碰撞层=0（不占任何层 → 不会被玩家子弹或敌人误伤），mask=1（仅检测 Player）。
## 与玩家子弹（小、快、黄）形成鲜明对比，便于玩家识别躲避。

var projectile_damage: int = 10
var projectile_speed: float = 130.0  # 慢，给玩家反应空间
var direction: Vector2 = Vector2.RIGHT

## 飞出地图边界多远后销毁
const DESPAWN_MARGIN: float = 100.0

var is_destroyed: bool = false
var _radius: float = 14.0  # 由 setup 写入，_ready 据此生成纹理与碰撞

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 大号占位纹理（紫红色方块，区别于玩家的黄色子弹）
	var s := maxi(int(_radius * 2.0), 6)
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.85, 0.25, 0.85))
	sprite.texture = ImageTexture.create_from_image(img)

	# 碰撞半径独立 shape（避免共享子资源导致半径耦合）
	var shape := CircleShape2D.new()
	shape.radius = _radius
	$CollisionShape2D.shape = shape

	# 旋转精灵朝向飞行方向
	if direction.length_squared() > 0.01:
		rotation = direction.angle()

	# 监测玩家 CharacterBody2D（mask=1 已在场景配置）
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	# 直线飞行
	position += direction * projectile_speed * delta

	# 飞出地图边界后销毁
	var map_size := game_manager.MAP_SIZE
	if global_position.x < -DESPAWN_MARGIN or global_position.x > map_size.x + DESPAWN_MARGIN \
			or global_position.y < -DESPAWN_MARGIN or global_position.y > map_size.y + DESPAWN_MARGIN:
		queue_free()


func setup(dmg: int, spd: float, dir: Vector2, radius: float) -> void:
	projectile_damage = dmg
	projectile_speed = spd
	direction = dir.normalized()
	_radius = maxf(radius, 4.0)


func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		return
	# 只伤害玩家
	if body == game_manager.player:
		if game_manager.player:
			combat_system.damage_player(projectile_damage, self)
		is_destroyed = true
		call_deferred("queue_free")
