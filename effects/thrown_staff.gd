extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")
const GroundZone = preload("res://effects/ground_zone.gd")

## 投掷棍子（棍子 L5「投掷旋转」用）：
## 朝方向飞出，碰到敌人或到最远射程后停止，原地留一个伤害+减速地面区域 3s（=棍子原地旋转的效果），随后回收。

var dir: Vector2 = Vector2.RIGHT
var speed: float = 520.0
var max_range: float = 520.0
var damage: float = 12.0
var hit_radius: float = 18.0
var element: int = DamageInfo.Element.NONE
var source_weapon: Node = null

var _traveled: float = 0.0
var _stopped: bool = false


func setup(p_dir: Vector2, p_speed: float, p_max_range: float, p_damage: float, p_element: int = DamageInfo.Element.NONE, p_source: Node = null) -> void:
	dir = p_dir.normalized()
	speed = p_speed
	max_range = p_max_range
	damage = p_damage
	element = p_element
	source_weapon = p_source


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if _stopped:
		return
	global_position += dir * speed * delta
	_traveled += speed * delta
	rotation += delta * 10.0
	# 碰到敌人 → 停止并原地旋转
	if enemy_spawner.enemies_container:
		for e in enemy_spawner.enemies_container.get_children():
			if not (e is CharacterBody2D) or not is_instance_valid(e):
				continue
			if global_position.distance_to(e.global_position) <= hit_radius:
				_stop_and_spin()
				return
	if _traveled >= max_range:
		_stop_and_spin()


## 停止：原地留一个伤害+减速地面区域 3s（棍子原地旋转），随后回收棍子。
func _stop_and_spin() -> void:
	_stopped = true
	var z := GroundZone.new()
	# 伤害 + 减速，持续 3s（不附元素以免与水反应；元素由棍子本体命中带）
	z.setup(50.0, damage * 0.5, 0.4, 3.0, DamageInfo.Element.NONE, true, source_weapon)
	z.global_position = global_position
	if is_instance_valid(get_parent()):
		get_parent().add_child(z)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-3.0, -10.0, 6.0, 20.0), Color(0.75, 0.55, 0.3))
