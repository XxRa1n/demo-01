extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 光束实体（激光用）：从玩家出发、锁定最近敌人方向、按帧 DPS 的持续光束。
## active_time 内持续造伤并跟随玩家/重新瞄准，之后 fade_time 淡出消失。
## 伤害用 is_dot=true（连续小伤害，不每帧掷暴击 / 不重复附着元素）。

var damage_per_sec: float = 14.0
var length: float = 540.0
var width: float = 16.0
var active_time: float = 1.0
var fade_time: float = 0.2
var element: int = DamageInfo.Element.NONE
var source_weapon: Node = null

var _time: float = 0.0
var _state: int = 0  # 0=active, 1=fade
var _dir: Vector2 = Vector2.RIGHT


func setup(p_dps: float, p_length: float, p_width: float, p_active: float, p_element: int = DamageInfo.Element.NONE, p_source: Node = null) -> void:
	damage_per_sec = p_dps
	length = p_length
	width = p_width
	active_time = p_active
	element = p_element
	source_weapon = p_source


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not is_instance_valid(game_manager.player):
		return
	_time += delta
	if _state == 0:
		global_position = game_manager.player.global_position
		var nearest := _find_nearest()
		if nearest != null:
			_dir = (nearest.global_position - global_position).normalized()
		_damage_along(delta)
		if _time >= active_time:
			_state = 1
			_time = 0.0
	else:
		if _time >= fade_time:
			queue_free()
	queue_redraw()


func _damage_along(delta: float) -> void:
	if not enemy_spawner.enemies_container:
		return
	var per_frame: float = damage_per_sec * delta
	for e in enemy_spawner.enemies_container.get_children():
		if not (e is CharacterBody2D) or not is_instance_valid(e):
			continue
		var rel: Vector2 = e.global_position - global_position
		var t: float = rel.dot(_dir)
		if t < 0.0 or t > length:
			continue
		var perp: float = (rel - _dir * t).length()
		if perp <= width * 0.5:
			var info := DamageInfo.new(per_frame, element, Vector2.ZERO, 0.0)
			info.is_dot = true
			info.source_weapon = source_weapon
			combat_system.damage_enemy(e, info)


func _find_nearest() -> CharacterBody2D:
	if not enemy_spawner.enemies_container:
		return null
	var nearest: CharacterBody2D = null
	var nd: float = INF
	for c in enemy_spawner.enemies_container.get_children():
		if c is CharacterBody2D and is_instance_valid(c):
			var d: float = c.global_position.distance_to(global_position)
			if d < nd:
				nd = d
				nearest = c
	return nearest


func _draw() -> void:
	var alpha: float = 1.0 if _state == 0 else clampf(1.0 - _time / fade_time, 0.0, 1.0)
	var col := _color(element, alpha)
	var end: Vector2 = _dir * length
	draw_line(Vector2.ZERO, end, col, width)
	draw_circle(Vector2.ZERO, width * 0.5, col)
	draw_circle(end, width * 0.7, col)


func _color(el: int, a: float) -> Color:
	var base_a: float = 0.6 * a
	match el:
		DamageInfo.Element.FIRE:
			return Color(1.0, 0.5, 0.2, base_a)
		DamageInfo.Element.WATER:
			return Color(0.3, 0.6, 1.0, base_a)
		DamageInfo.Element.ICE:
			return Color(0.7, 0.9, 1.0, base_a)
		DamageInfo.Element.LIGHTNING:
			return Color(0.9, 0.9, 1.0, base_a)
		DamageInfo.Element.GRASS:
			return Color(0.5, 1.0, 0.4, base_a)
		_:
			return Color(0.4, 0.8, 1.0, base_a)
