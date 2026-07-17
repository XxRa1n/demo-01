extends Node2D

const DamageInfo = preload("res://scripts/combat/damage_info.gd")
const Beam = preload("res://effects/beam.gd")
const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

## 召唤物（炮台/猫/龙/熊用）：环绕玩家公转，周期自动攻击射程内最近敌人。
## attack_kind: "aoe"=自身周围 AoE 脉冲(猫/龙/熊)；"ranged"=发射直射弹(炮台)。

var orbit_radius: float = 60.0
var orbit_speed: float = 2.0
var base_angle: float = 0.0
var angle: float = 0.0

var attack_range: float = 160.0
var attack_interval: float = 0.8
var attack_radius: float = 45.0   # aoe 半径
var damage: float = 8.0
var proj_speed: float = 520.0
var attack_kind: String = "aoe"
var element: int = DamageInfo.Element.NONE
var source_weapon: Node = null
var color: Color = Color(0.8, 0.6, 0.4)
var size: int = 16
var charge: bool = false        # 横冲直撞：朝最近敌人冲锋而非环绕玩家
var follow_speed: float = 240.0

var _timer: float = 0.0


func setup(p_orbit_r: float, p_orbit_spd: float, p_atk_range: float, p_atk_interval: float, p_atk_radius: float, p_damage: float, p_kind: String, p_color: Color, p_size: int, p_element: int = DamageInfo.Element.NONE, p_source: Node = null) -> void:
	orbit_radius = p_orbit_r
	orbit_speed = p_orbit_spd
	attack_range = p_atk_range
	attack_interval = p_atk_interval
	attack_radius = p_atk_radius
	damage = p_damage
	attack_kind = p_kind
	color = p_color
	size = p_size
	element = p_element
	source_weapon = p_source


func set_base_angle(a: float) -> void:
	base_angle = a


func set_charge(c: bool) -> void:
	charge = c


func _physics_process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not is_instance_valid(game_manager.player):
		return
	if charge:
		# 横冲直撞：朝最近敌人冲锋，无敌人则回玩家身边
		var tgt := _find_nearest_any()
		var dest: Vector2 = tgt.global_position if tgt != null else game_manager.player.global_position
		global_position = global_position.move_toward(dest, follow_speed * delta)
	else:
		angle = fmod(angle + orbit_speed * delta, TAU)
		global_position = game_manager.player.global_position + Vector2.from_angle(base_angle + angle) * orbit_radius

	_timer -= delta
	if _timer <= 0.0:
		var nearest := _find_nearest_in_range()
		if nearest != null:
			_timer = attack_interval
			_attack(nearest)
		else:
			_timer = 0.2  # 无目标，稍后重试
	queue_redraw()


func _attack(nearest: Node) -> void:
	if attack_kind == "ranged":
		var dir: Vector2 = (nearest.global_position - global_position).normalized()
		var proj := projectile_scene.instantiate()
		proj.setup(damage, proj_speed, dir, 0, element, source_weapon)
		proj.global_position = global_position
		if is_instance_valid(get_parent()):
			get_parent().add_child(proj)
	elif attack_kind == "beam":
		# 炮台 L5 发射 laser：朝最近敌人射一束短光束
		var b := Beam.new()
		b.setup(damage * 3.0, 360.0, 12.0, 0.3, element, source_weapon)
		b.global_position = global_position
		if is_instance_valid(get_parent()):
			get_parent().add_child(b)
	elif attack_kind == "triple_flame":
		# 龙 L5 三条火焰：朝目标方向扇形喷 3 道火
		var base_dir: Vector2 = (nearest.global_position - global_position).normalized()
		for i in 3:
			var dir := base_dir.rotated(deg_to_rad(-25.0 + 25.0 * float(i)))
			var proj := projectile_scene.instantiate()
			proj.setup(damage, proj_speed, dir, 0, DamageInfo.Element.FIRE, source_weapon)
			proj.global_position = global_position
			if is_instance_valid(get_parent()):
				get_parent().add_child(proj)
	else:
		# 自身周围 AoE
		if enemy_spawner.enemies_container:
			for e in enemy_spawner.enemies_container.get_children():
				if not (e is CharacterBody2D) or not is_instance_valid(e):
					continue
				if global_position.distance_to(e.global_position) > attack_radius:
					continue
				var info := DamageInfo.new(damage, element, Vector2.ZERO, 0.0)
				info.source_weapon = source_weapon
				combat_system.damage_enemy(e, info)


func _find_nearest_in_range() -> Node:
	if not enemy_spawner.enemies_container:
		return null
	var nearest: Node = null
	var nd: float = attack_range
	for c in enemy_spawner.enemies_container.get_children():
		if c is CharacterBody2D and is_instance_valid(c):
			var d: float = global_position.distance_to(c.global_position)
			if d < nd:
				nd = d
				nearest = c
	return nearest


## 不限范围的最近敌人（横冲直撞用）。
func _find_nearest_any() -> Node:
	if not enemy_spawner.enemies_container:
		return null
	var nearest: Node = null
	var nd: float = INF
	for c in enemy_spawner.enemies_container.get_children():
		if c is CharacterBody2D and is_instance_valid(c):
			var d: float = global_position.distance_to(c.global_position)
			if d < nd:
				nd = d
				nearest = c
	return nearest


func _draw() -> void:
	draw_circle(Vector2.ZERO, float(size), color)
	draw_arc(Vector2.ZERO, float(size), 0.0, TAU, 20, Color(1, 1, 1, 0.5), 1.0)
