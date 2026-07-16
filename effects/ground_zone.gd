extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 地面持续区域（喷火岩浆池 / 矮人榴弹炮地震炮用）：在原地存在 duration 秒，
## 每 tick_interval 对范围内敌人造成一次伤害（is_dot）；可选附元素（火→燃烧）或减速（水）。
## 注意：element 与 slow 二选一配置，避免同时触发火+水反应。

var radius: float = 60.0
var damage_per_tick: float = 4.0
var tick_interval: float = 0.5
var duration: float = 5.0
var element: int = DamageInfo.Element.NONE  # != NONE 时每 tick 附该元素（raw，不触发反应）
var slow: bool = false                        # true 时每 tick 附水（减速）
var source_weapon: Node = null

var _time: float = 0.0
var _tick: float = 0.0


func setup(p_radius: float, p_dmg: float, p_tick: float, p_duration: float, p_element: int = DamageInfo.Element.NONE, p_slow: bool = false, p_source: Node = null) -> void:
	radius = p_radius
	damage_per_tick = p_dmg
	tick_interval = p_tick
	duration = p_duration
	element = p_element
	slow = p_slow
	source_weapon = p_source


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	_time += delta
	_tick += delta
	if _tick >= tick_interval:
		_tick = 0.0
		_do_tick()
	if _time >= duration:
		queue_free()
	queue_redraw()


func _do_tick() -> void:
	if not enemy_spawner.enemies_container:
		return
	for e in enemy_spawner.enemies_container.get_children():
		if not (e is CharacterBody2D) or not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) > radius:
			continue
		var info := DamageInfo.new(damage_per_tick, DamageInfo.Element.NONE, Vector2.ZERO, 0.0)
		info.is_dot = true
		info.source_weapon = source_weapon
		combat_system.damage_enemy(e, info)
		var sh = e.get("status")
		if sh != null and is_instance_valid(sh) and sh.has_method("apply_raw"):
			if element != DamageInfo.Element.NONE:
				sh.apply_raw(element, damage_per_tick * 0.2)
			elif slow:
				sh.apply_raw(DamageInfo.Element.WATER, 1.0)


func _draw() -> void:
	var alpha: float = clampf(1.0 - _time / duration, 0.0, 1.0)
	var col: Color = Color(1.0, 0.45, 0.2, 0.35 * alpha) if element == DamageInfo.Element.FIRE else Color(0.7, 0.6, 0.4, 0.35 * alpha)
	draw_circle(Vector2.ZERO, radius, col)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.7 * alpha), 2.0)
