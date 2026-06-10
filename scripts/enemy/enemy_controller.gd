extends CharacterBody2D

## 敌人属性（由 spawner 设置）
var enemy_hp: float = 8.0
var enemy_speed: float = 60.0
var contact_damage: int = 5

## 信号
signal enemy_died(position: Vector2)

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea


func _ready() -> void:
	# 生成占位纹理（红色方块）
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.85, 0.2, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)

	# 连接伤害区检测（碰到玩家 CharacterBody2D）
	damage_area.body_entered.connect(_on_damage_body_entered)


func setup(hp: float, spd: float, dmg: int) -> void:
	enemy_hp = hp
	enemy_speed = spd
	contact_damage = dmg


func _physics_process(_delta: float) -> void:
	if game_manager.game_over:
		return
	if not game_manager.player:
		return

	# 朝玩家方向移动
	var direction := (game_manager.player.global_position - global_position).normalized()
	velocity = direction * enemy_speed
	move_and_slide()


func take_damage(amount: float) -> void:
	enemy_hp -= amount
	if enemy_hp <= 0.0:
		enemy_died.emit(global_position)
		game_manager.add_kill()
		call_deferred("queue_free")


func _on_damage_body_entered(body: Node2D) -> void:
	# 如果碰到玩家，对玩家造成伤害
	if body == game_manager.player:
		if game_manager.player:
			game_manager.player.take_damage(contact_damage)
