extends WeaponBase

## 竖琴（ProjectileBase·特殊）：随机方向发射音符。L5 集 do/re/mi 触发圆形范围伤害。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const NOTE_SPEED: float = 560.0

var _notes: Dictionary = {}  # 已收集音符


func _init() -> void:
	weapon_id = &"harp"
	display_name = "竖琴"
	weapon_icon_color = Color(0.95, 0.6, 0.9)
	base_damage = 9.0
	base_cooldown = 1.0
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	var n: int = 1 + _count_bonus
	var dmg := _calc_damage()
	var pierce: int = _pierce_bonus
	var speed := NOTE_SPEED * _size_mult
	var el := _gem_element()
	for _i in n:
		var dir := Vector2.from_angle(randf() * TAU)
		var proj := projectile_scene.instantiate()
		proj.setup(dmg, speed, dir, pierce, el, self)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)
	if _l5_active:
		# 集 do re mi：每次随机收集一个，集齐三个 → 圆形范围伤害并清空
		var note: String = ["do", "re", "mi"][randi() % 3]
		_notes[note] = true
		if _notes.size() >= 3:
			_notes.clear()
			_aoe_burst()


## 圆形范围伤害（集齐 do re mi 触发）。
func _aoe_burst() -> void:
	if not enemy_spawner.enemies_container:
		return
	var center := game_manager.player.global_position
	var r := 140.0 * _size_mult
	for e in enemy_spawner.enemies_container.get_children():
		if e is CharacterBody2D and is_instance_valid(e) and center.distance_to(e.global_position) <= r:
			var info := DamageInfo.new(_calc_damage() * 1.5, _gem_element(), Vector2.ZERO, 0.0)
			info.source_weapon = self
			combat_system.damage_enemy(e, info)


func _apply_special() -> void:  # L5 do re mi 圆形范围伤害
	pass
