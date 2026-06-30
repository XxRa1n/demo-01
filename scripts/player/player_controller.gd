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

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup_area: Area2D = $PickupArea
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	game_manager.register_player(self)
	# 生成占位纹理（蓝色方块）
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.5, 1.0))
	sprite.texture = ImageTexture.create_from_image(img)
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
