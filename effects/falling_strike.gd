extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 空中掉落打击（火枪 L5 用）：从目标敌人正上方高空落下一发子弹，落地时对该处小范围敌人造成伤害。
## 由武器选定一个目标位置后生成；下落过程为视觉表现，落地结算 AoE。

var target_pos: Vector2 = Vector2.ZERO
var damage: float = 10.0
var radius: float = 40.0
var fall_speed: float = 900.0
var element: int = DamageInfo.Element.NONE
var source_weapon: Node = null

const START_HEIGHT: float = 260.0
var _travel: float = 0.0


func setup(p_target: Vector2, p_damage: float, p_radius: float, p_element: int = DamageInfo.Element.NONE, p_source: Node = null) -> void:
	target_pos = p_target
	damage = p_damage
	radius = p_radius
	element = p_element
	source_weapon = p_source
	global_position = p_target + Vector2(0.0, -START_HEIGHT)
	_travel = 0.0


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	_travel += fall_speed * delta
	global_position.y += fall_speed * delta
	if _travel >= START_HEIGHT:
		_impact()
		queue_free()
	queue_redraw()


func _impact() -> void:
	if not enemy_spawner.enemies_container:
		return
	for e in enemy_spawner.enemies_container.get_children():
		if not (e is CharacterBody2D) or not is_instance_valid(e):
			continue
		if target_pos.distance_to(e.global_position) > radius:
			continue
		var info := DamageInfo.new(damage, element, Vector2.ZERO, 0.0)
		info.source_weapon = source_weapon
		combat_system.damage_enemy(e, info)


func _draw() -> void:
	# 落下的子弹
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.85, 0.3))
	# 目标处的落点提示
	var to_target := target_pos - global_position
	draw_circle(to_target, radius, Color(1.0, 0.3, 0.2, 0.25))
