extends Area2D

## 子弹属性（由武器设置）
var projectile_damage: float = 10.0
var projectile_speed: float = 400.0
var pierce_count: int = 0  # 0 = 击中即消失，1 = 穿透1个敌人
var direction: Vector2 = Vector2.RIGHT

## 飞出地图边界多远后销毁（子弹不与墙碰撞，会越过边界）
const DESPAWN_MARGIN: float = 100.0

## 状态
var hit_count: int = 0
var is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 生成占位纹理（黄色方块）
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.9, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)

	# 旋转精灵朝向飞行方向
	if direction.length_squared() > 0.01:
		rotation = direction.angle()

	# 连接碰撞检测（子弹 Area2D 碰到敌人 CharacterBody2D）
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return

	# 直线飞行
	position += direction * projectile_speed * delta

	# 飞出地图边界后销毁（设计：子弹一直飞到地图边缘，仅因撞敌或越界消失）
	var map_size := game_manager.MAP_SIZE
	if global_position.x < -DESPAWN_MARGIN or global_position.x > map_size.x + DESPAWN_MARGIN \
			or global_position.y < -DESPAWN_MARGIN or global_position.y > map_size.y + DESPAWN_MARGIN:
		queue_free()


func setup(dmg: float, spd: float, dir: Vector2, pierce: int) -> void:
	projectile_damage = dmg
	projectile_speed = spd
	direction = dir.normalized()
	pierce_count = pierce


func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		return

	# 检查是否击中敌人
	if body is CharacterBody2D and body.has_method("take_damage"):
		body.take_damage(projectile_damage)
		hit_count += 1

		# 检查穿透次数
		if hit_count > pierce_count:
			is_destroyed = true
			call_deferred("queue_free")
