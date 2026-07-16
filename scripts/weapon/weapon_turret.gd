extends WeaponBase

## 炮台（Minion·Turret）：环绕炮台，自动发射直射弹。L5 发射 laser（伤害）。

const Minion = preload("res://effects/minion.gd")


func _init() -> void:
	weapon_id = &"turret"
	display_name = "炮台"
	weapon_icon_color = Color(0.5, 0.5, 0.6)
	base_damage = 8.0
	base_cooldown = 0.5
	_count_supported = true


func _fire() -> void:
	var dmg := _calc_damage()
	_sync_minions(func(): return Minion.new(), 1, func(m, i, n):
		m.setup(72.0, 1.2, 360.0 * _size_mult, 1.0, 0.0, dmg, "ranged", Color(0.5, 0.5, 0.6), 14, _gem_element())
		m.set_base_angle(float(i) / float(n) * TAU)
	)


func _apply_special() -> void:  # L5 发射 laser
	_dmg_mult *= 1.4
