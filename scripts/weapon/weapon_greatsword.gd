extends WeaponBase

## 巨剑（SlashArea）：更宽更大的斩击，高伤慢速。L5 巨剑变大（范围 + 伤害）。

const Slash = preload("res://effects/slash.gd")


func _init() -> void:
	weapon_id = &"greatsword"
	display_name = "巨剑"
	weapon_icon_color = Color(0.7, 0.7, 0.8)
	base_damage = 20.0
	base_cooldown = 1.3


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var s := Slash.new()
	s.setup(140.0 * _size_mult, 2.2, _calc_damage(), 360.0 * _kb_mult, facing)
	s.element = _gem_element()
	s.source_weapon = self
	s.global_position = game_manager.player.global_position
	projectiles_container.add_child(s)


func _apply_special() -> void:  # L5 巨剑变大
	_size_mult *= 1.4
	_dmg_mult *= 1.2
