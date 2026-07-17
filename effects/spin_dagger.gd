extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 旋转匕首（匕首 L5「最远射程处旋转」用）：
## 朝方向飞到最远射程，随后原地旋转，对半径内敌人周期造成伤害，到期消失。

var dir: Vector2 = Vector2.RIGHT
var speed: float = 760.0
var max_range: float = 380.0
var damage: float = 5.0
var spin_duration: float = 1.5
var spin_radius: float = 42.0
var element: int = DamageInfo.Element.NONE
var source_weapon: Node = null

var _traveled: float = 0.0
var _state: int = 0  # 0=飞行, 1=旋转
var _spin_time: float = 0.0
var _tick: float = 0.0


func setup(p_dir: Vector2, p_speed: float, p_max_range: float, p_damage: float, p_spin_duration: float, p_spin_radius: float, p_element: int = DamageInfo.Element.NONE, p_source: Node = null) -> void:
	dir = p_dir.normalized()
	speed = p_speed
	max_range = p_max_range
	damage = p_damage
	spin_duration = p_spin_duration
	spin_radius = p_spin_radius
	element = p_element
	source_weapon = p_source


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if _state == 0:
		global_position += dir * speed * delta
		_traveled += speed * delta
		if _traveled >= max_range:
			_state = 1
	else:
		_spin_time += delta
		_tick += delta
		rotation += delta * 14.0  # 旋转视觉
		if _tick >= 0.3:
			_tick = 0.0
			_spin_damage()
		if _spin_time >= spin_duration:
			queue_free()
	queue_redraw()


func _spin_damage() -> void:
	if not enemy_spawner.enemies_container:
		return
	for e in enemy_spawner.enemies_container.get_children():
		if not (e is CharacterBody2D) or not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) > spin_radius:
			continue
		var info := DamageInfo.new(damage, element, Vector2.ZERO, 0.0)
		info.is_dot = true
		info.source_weapon = source_weapon
		combat_system.damage_enemy(e, info)


func _draw() -> void:
	var col := Color(0.85, 0.85, 0.9)
	draw_rect(Rect2(-3.0, -8.0, 6.0, 16.0), col)
	if _state == 1:
		draw_arc(Vector2.ZERO, spin_radius, 0.0, TAU, 24, Color(0.85, 0.85, 0.9, 0.3), 1.0)
