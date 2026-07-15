extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 扩散波实体（声波 / 喷火用）：从原点向外扩散，扫到的敌人各受一次伤害（+击退 / +元素）。
## arc=TAU 为全圆环（声波）；arc<TAU 为朝 facing 的扇形（喷火）。
## 每个敌人每波只受一次伤害（_hit 去重）。

var expand_speed: float = 280.0
var max_radius: float = 240.0
var damage: float = 10.0
var knockback: float = 200.0
var arc: float = TAU
var facing: Vector2 = Vector2.RIGHT
var element: int = DamageInfo.Element.NONE
var source_weapon: Node = null

var _radius: float = 0.0
var _hit: Dictionary = {}


func setup(p_speed: float, p_max_r: float, p_damage: float, p_knockback: float, p_arc: float = TAU, p_facing: Vector2 = Vector2.RIGHT, p_element: int = DamageInfo.Element.NONE, p_source: Node = null) -> void:
	expand_speed = p_speed
	max_radius = p_max_r
	damage = p_damage
	knockback = p_knockback
	arc = p_arc
	facing = p_facing
	element = p_element
	source_weapon = p_source


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	_radius += expand_speed * delta
	if enemy_spawner.enemies_container:
		var half_arc: float = arc * 0.5
		for e in enemy_spawner.enemies_container.get_children():
			if not (e is CharacterBody2D) or not is_instance_valid(e):
				continue
			var rid: int = e.get_instance_id()
			if _hit.has(rid):
				continue
			var rel: Vector2 = e.global_position - global_position
			var d: float = rel.length()
			if d > _radius:
				continue
			# 扇形角度检查（全圆 arc>=TAU 时跳过）
			if arc < TAU and d > 0.001:
				var ang: float = abs(rel.angle_to(facing))
				if ang > half_arc:
					continue
			var kdir: Vector2 = rel.normalized() if d > 0.001 else facing
			var info := DamageInfo.new(damage, element, kdir, knockback)
			info.source_weapon = source_weapon
			combat_system.damage_enemy(e, info)
			_hit[rid] = true
	if _radius >= max_radius:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var alpha: float = clampf(1.0 - _radius / max_radius, 0.0, 1.0)
	var col := _color(element, alpha)
	var a0: float = (facing.angle() - arc * 0.5) if arc < TAU else 0.0
	var a1: float = a0 + (arc if arc < TAU else TAU)
	draw_arc(Vector2.ZERO, _radius, a0, a1, 36, col, 3.0)


func _color(el: int, a: float) -> Color:
	var base_a: float = 0.55 * a
	match el:
		DamageInfo.Element.FIRE:
			return Color(1.0, 0.45, 0.2, base_a)
		DamageInfo.Element.GRASS:
			return Color(0.5, 1.0, 0.4, base_a)
		_:
			return Color(0.8, 0.9, 1.0, base_a)
