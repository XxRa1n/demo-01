extends Area2D

## XP 宝石属性
var xp_value: int = 1
var magnet_speed: float = 400.0
var is_attracted: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 生成占位纹理（绿色菱形 → 绿色方块）
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.8, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not game_manager.player:
		return

	var player_pos := game_manager.player.global_position
	var dist: float = global_position.distance_to(player_pos)
	var pickup_range: float = game_manager.player.pickup_range

	if dist <= pickup_range:
		# 进入拾取范围，加速飞向玩家
		is_attracted = true

	if is_attracted:
		var direction := (player_pos - global_position).normalized()
		global_position += direction * magnet_speed * delta
		# 接触即拾取
		if dist < 16.0:
			upgrade_manager.add_xp(xp_value)
			queue_free()
