extends Node2D

## 连锁闪电（水+雷 / 冰+雷 反应产物）：从原点向最近敌人跳跃 N 跳，每跳伤害衰减，绘制折线。
## 伤害用 is_reaction=true 的 DamageInfo（不触发反应、不附着元素）。

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

const LIFE: float = 0.25

var jumps: int = 3
var damage: float = 10.0
var radius: float = 160.0
var decay: float = 0.8
var _life: float = LIFE
var _points: PackedVector2Array = []


func setup(p_damage: float, p_jumps: int = 3, p_radius: float = 160.0, p_decay: float = 0.8) -> void:
	damage = p_damage
	jumps = p_jumps
	radius = p_radius
	decay = p_decay


func _ready() -> void:
	_points.append(Vector2.ZERO)  # 起点（相对自身）
	var from: Vector2 = global_position
	var dmg: float = damage
	var hit_ids: Array = []
	if enemy_spawner.enemies_container:
		for _i in jumps:
			var best: Node = null
			var best_d: float = radius
			for e in enemy_spawner.enemies_container.get_children():
				if not is_instance_valid(e):
					continue
				if hit_ids.has(e.get_instance_id()):
					continue
				var d: float = from.distance_to(e.global_position)
				if d < best_d:
					best_d = d
					best = e
			if best == null:
				break
			hit_ids.append(best.get_instance_id())
			var info := DamageInfo.new(dmg, DamageInfo.Element.NONE, Vector2.ZERO, 0.0)
			info.is_reaction = true
			combat_system.damage_enemy(best, info)
			_points.append(best.global_position - global_position)
			from = best.global_position
			dmg *= decay


func _process(delta: float) -> void:
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _draw() -> void:
	if _points.size() < 2:
		return
	var alpha: float = _life / LIFE
	for i in _points.size() - 1:
		draw_line(_points[i], _points[i + 1], Color(0.6, 0.8, 1.0, alpha), 2.0)
	# 起点光点
	draw_circle(_points[0], 4.0, Color(0.85, 0.95, 1.0, alpha))
