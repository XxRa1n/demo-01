extends WeaponBase

## 激光（Beam）：锁定最近敌人的持续光束，按帧 DPS。L5 X 型光线（更长更宽）。

const Beam = preload("res://effects/beam.gd")


func _init() -> void:
	weapon_id = &"laser"
	display_name = "激光"
	weapon_icon_color = Color(0.4, 0.8, 1.0)
	base_damage = 12.0
	base_cooldown = 1.5


func _fire() -> void:
	var beam := Beam.new()
	beam.setup(_calc_damage() * 3.0, 540.0 * _size_mult, 16.0 * _size_mult, 1.0, _gem_element(), self)
	beam.global_position = game_manager.player.global_position
	projectiles_container.add_child(beam)


func _apply_special() -> void:  # L5 发射 X 型光线
	_size_mult *= 1.3
