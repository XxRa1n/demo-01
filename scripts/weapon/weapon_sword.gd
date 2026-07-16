extends WeaponBase

## 长剑（SlashArea）：瞬时扇形斩击 + 强击退。L5 月光大剑的波（斩击同时向前发出一道飞行波）。

const Slash = preload("res://effects/slash.gd")
const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")


func _init() -> void:
	weapon_id = &"sword"
	display_name = "长剑"
	weapon_icon_color = Color(0.9, 0.9, 0.95)
	base_damage = 14.0
	base_cooldown = 0.9
	_pierce_supported = true


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var s := Slash.new()
	s.setup(120.0 * _size_mult, 1.75, _calc_damage(), 300.0 * _kb_mult, facing)
	s.element = _gem_element()
	s.source_weapon = self
	s.global_position = game_manager.player.global_position
	projectiles_container.add_child(s)
	# L5 月光大剑的波：向前发射一道穿透波
	if _l5_active and nearest != null:
		var wave := projectile_scene.instantiate()
		wave.setup(_calc_damage() * 0.8, 560.0 * _size_mult, facing, 2 + _pierce_bonus, _gem_element(), self)
		wave.global_position = game_manager.player.global_position
		projectiles_container.add_child(wave)


func _apply_special() -> void:  # L5 月光大剑的波
	pass
