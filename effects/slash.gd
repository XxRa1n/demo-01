extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 斩击区域（长剑/巨剑/棍子用）：朝 facing 方向的瞬时扇形斩击，命中范围内全部敌人一次 + 击退。
## _ready 时立即结算命中，随后短暂淡出消失。

const LIFE: float = 0.18

var radius: float = 120.0
var arc: float = 1.75       # ~100°
var damage: float = 14.0
var knockback: float = 300.0
var facing: Vector2 = Vector2.RIGHT
var element: int = DamageInfo.Element.NONE
var source_weapon: Node = null

var _life: float = LIFE


func setup(p_radius: float, p_arc: float, p_damage: float, p_knockback: float, p_facing: Vector2, p_element: int = DamageInfo.Element.NONE, p_source: Node = null) -> void:
	radius = p_radius
	arc = p_arc
	damage = p_damage
	knockback = p_knockback
	facing = p_facing
	element = p_element
	source_weapon = p_source


func _ready() -> void:
	var half_arc: float = arc * 0.5
	if enemy_spawner.enemies_container:
		for e in enemy_spawner.enemies_container.get_children():
			if not (e is CharacterBody2D) or not is_instance_valid(e):
				continue
			var rel: Vector2 = e.global_position - global_position
			var d: float = rel.length()
			if d > radius:
				continue
			if d > 0.001 and abs(rel.angle_to(facing)) > half_arc:
				continue
			var kdir: Vector2 = rel.normalized() if d > 0.001 else facing
			var info := DamageInfo.new(damage, element, kdir, knockback)
			info.source_weapon = source_weapon
			combat_system.damage_enemy(e, info)


func _process(delta: float) -> void:
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _draw() -> void:
	var alpha: float = clampf(_life / LIFE, 0.0, 1.0)
	var col := Color(1.0, 1.0, 1.0, 0.5 * alpha)
	var a0: float = facing.angle() - arc * 0.5
	# 扇形外弧
	draw_arc(Vector2.ZERO, radius, a0, a0 + arc, 24, col, 3.0)
	# 扇形两条边
	draw_line(Vector2.ZERO, Vector2.from_angle(a0) * radius, col, 2.0)
	draw_line(Vector2.ZERO, Vector2.from_angle(a0 + arc) * radius, col, 2.0)
