extends CharacterBody2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 玩家属性
var max_hp: int = 100
var hp: int = 100
var speed: float = 160.0
var might: float = 1.0
var cooldown_mult: float = 1.0
var pickup_range: float = 30.0
var armor: int = 0

## 战斗属性（Phase 2：暴击 / 吸血 / 斩杀；Phase 5 起由宝石提供）
var crit_rate: float = 0.0           # 暴击概率 [0,1]
var crit_damage_mult: float = 1.5    # 暴击伤害倍率（暴击时 amt × 此值）
var lifesteal_pct: float = 0.0       # 吸血比例（造成伤害时按此回血）
var execute_enabled: bool = false    # 是否开启斩杀（低血敌人直接秒杀）

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


## 治疗（吸血等用）：不超过 max_hp，并同步 damaged 信号供 HUD 更新。
func heal(amount: int) -> void:
	if amount <= 0 or game_manager.game_over:
		return
	hp = min(hp + amount, max_hp)
	damaged.emit(hp, max_hp)


# DEBUG（仅调试构建）：数字键 1/2/3 临时授予暴击 / 吸血 / 斩杀，供测试。
# Phase 5 起这些属性由宝石正式提供，届时删除本调试段。
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1:
			crit_rate = minf(crit_rate + 0.25, 1.0)
			crit_damage_mult += 0.5
		KEY_2:
			lifesteal_pct += 0.05
		KEY_3:
			execute_enabled = not execute_enabled
		KEY_5:
			_debug_apply_element(DamageInfo.Element.FIRE)
		KEY_6:
			_debug_apply_element(DamageInfo.Element.WATER)
		KEY_7:
			_debug_apply_element(DamageInfo.Element.ICE)
		KEY_8:
			_debug_apply_element(DamageInfo.Element.LIGHTNING)
		KEY_9:
			_debug_apply_element(DamageInfo.Element.GRASS)


## DEBUG：对附近敌人直接附着元素，验证状态系统（Phase 5 起元素改由宝石武器命中触发）。
func _debug_apply_element(element: int) -> void:
	if not enemy_spawner.enemies_container:
		return
	var center := global_position
	for e in enemy_spawner.enemies_container.get_children():
		if not is_instance_valid(e):
			continue
		if center.distance_to(e.global_position) > 320.0:
			continue
		var sh = e.get("status")
		if sh != null and is_instance_valid(sh) and sh.has_method("apply"):
			sh.apply(element, 6.0)
