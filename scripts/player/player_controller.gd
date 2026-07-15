extends CharacterBody2D

## 玩家属性
var max_hp: int = 100
var hp: int = 100
var speed: float = 160.0
var might: float = 1.0
var cooldown_mult: float = 1.0
var pickup_range: float = 30.0
var armor: int = 0

## 无敌帧
var is_invincible: bool = false
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 0.5

## 信号
signal damaged(current_hp: int, max_hp: int)
signal died()

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var pickup_area: Area2D = $PickupArea
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	game_manager.register_player(self)
	# 默认播放向右行走动画（玩家始终朝向最后移动的水平方向）
	sprite.play("walk_right")
	# 玩家出生在地图中心
	global_position = game_manager.MAP_CENTER
	# 限制镜头不超出地图边界
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = game_manager.MAP_SIZE.x
	camera.limit_bottom = game_manager.MAP_SIZE.y


func _physics_process(delta: float) -> void:
	if game_manager.game_over:
		return

	# 无敌帧计时
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			is_invincible = false
			sprite.visible = true
		else:
			sprite.visible = !sprite.visible  # 闪烁效果

	# 移动输入
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	if input_dir.length_squared() > 0.01:
		input_dir = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()

	# 根据水平移动方向切换左右朝向动画（每个动画只有 1 帧，相当于方向指示）
	if input_dir.x < -0.01 and sprite.animation != &"walk_left":
		sprite.play("walk_left")
	elif input_dir.x > 0.01 and sprite.animation != &"walk_right":
		sprite.play("walk_right")

	# 更新拾取区大小
	var pickup_shape: CircleShape2D = pickup_area.get_node("CollisionShape2D").shape
	pickup_shape.radius = pickup_range


func take_damage(amount: int) -> void:
	if is_invincible or game_manager.game_over:
		return

	var final_damage: int = max(amount - armor, 1)
	hp -= final_damage
	hp = max(hp, 0)

	is_invincible = true
	invincible_timer = INVINCIBLE_DURATION

	damaged.emit(hp, max_hp)

	if hp <= 0:
		game_manager.game_over = true
		game_manager.game_won = false
		game_manager.game_ended.emit(false)
		died.emit()
