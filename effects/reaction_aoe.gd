extends Node2D

## 通用反应 AoE：在 global_position 生成，对半径内敌人造成一次性伤害 / 附着元素，0.3s 后消失。
## 由 reaction_engine 配置：radius / damage / apply_element / color。
## 伤害用 is_reaction=true 的 DamageInfo（不触发反应、不附着元素）；
## 附元素用 StatusHandler.apply_raw（裸附着，不触发反应）——双保险防链式反应。

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

const LIFE: float = 0.3

var radius: float = 90.0
var damage: float = 0.0
var apply_element: int = DamageInfo.Element.NONE
var _color: Color = Color(1.0, 0.8, 0.3, 0.5)
var _life: float = LIFE


func setup(p_radius: float, p_damage: float, p_element: int = DamageInfo.Element.NONE, p_color: Color = Color(1.0, 0.8, 0.3, 0.5)) -> void:
	radius = p_radius
	damage = p_damage
	apply_element = p_element
	_color = p_color


func _ready() -> void:
	# 立即结算：遍历敌人容器，对半径内敌人施加效果
	var center := global_position
	if enemy_spawner.enemies_container:
		for e in enemy_spawner.enemies_container.get_children():
			if not is_instance_valid(e):
				continue
			if center.distance_to(e.global_position) > radius:
				continue
			if damage > 0.0:
				var info := DamageInfo.new(damage, DamageInfo.Element.NONE, Vector2.ZERO, 0.0)
				info.is_reaction = true
				combat_system.damage_enemy(e, info)
			if apply_element != DamageInfo.Element.NONE:
				var sh = e.get("status")
				if sh != null and is_instance_valid(sh) and sh.has_method("apply_raw"):
					sh.apply_raw(apply_element, damage * 0.2)


func _process(delta: float) -> void:
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()


func _draw() -> void:
	var t: float = clampf(1.0 - _life / LIFE, 0.0, 1.0)
	var r: float = radius * t
	var alpha: float = 1.0 - t
	draw_circle(Vector2.ZERO, r, Color(_color.r, _color.g, _color.b, _color.a * alpha))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(_color.r, _color.g, _color.b, alpha), 2.0)
