extends Area2D

## 宝石掉落物（敌人死亡掉落）：磁吸拾取，进玩家宝石库存。
## 仿 xp_gem 的磁吸/拾取模式；颜色随宝石类型变化。

var gem_id: StringName = &""
var magnet_speed: float = 420.0
var is_attracted: bool = false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	img.fill(_color())
	sprite.texture = ImageTexture.create_from_image(img)


## 颜色：元素宝石用元素色，其余按类别（金=全局 / 银=fire_mod）。
func _color() -> Color:
	var d: Dictionary = gem_registry.get_def(gem_id)
	match d.get("cat", null):
		gem_registry.Cat.ELEMENT:
			return _element_color()
		gem_registry.Cat.GLOBAL, gem_registry.Cat.GLOBAL_FLAG:
			return Color(1.0, 0.82, 0.25)
		_:
			return Color(0.8, 0.8, 0.85)


func _element_color() -> Color:
	# 元素宝石在 registry 里带 element 字段
	var el: int = int(gem_registry.get_def(gem_id).get("element", 0))
	match el:
		1: return Color(1.0, 0.4, 0.2)   # FIRE
		2: return Color(0.3, 0.6, 1.0)   # WATER
		3: return Color(0.7, 0.9, 1.0)   # ICE
		4: return Color(0.9, 0.9, 1.0)   # LIGHTNING
		5: return Color(0.5, 1.0, 0.4)   # GRASS
		_: return Color(1.0, 0.82, 0.25)


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not game_manager.player:
		return

	var player_pos := game_manager.player.global_position
	var dist: float = global_position.distance_to(player_pos)
	if dist <= game_manager.player.pickup_range:
		is_attracted = true

	if is_attracted:
		var direction := (player_pos - global_position).normalized()
		global_position += direction * magnet_speed * delta
		if dist < 16.0:
			game_manager.player.add_gem(gem_id)
			queue_free()
