extends WeaponBase

## 熊（Minion·Follower）：跟随的重型大范围 AoE。L5 横冲直撞（范围 + 伤害）。

const Minion = preload("res://effects/minion.gd")


func _init() -> void:
	weapon_id = &"bear"
	display_name = "熊"
	weapon_icon_color = Color(0.5, 0.4, 0.3)
	base_damage = 16.0
	base_cooldown = 0.5
	_count_supported = true


func _fire() -> void:
	var dmg := _calc_damage()
	_sync_minions(func(): return Minion.new(), 1, func(m, i, n):
		m.setup(80.0, 1.6, 150.0 * _size_mult, 1.4, 70.0 * _size_mult, dmg, "aoe", Color(0.5, 0.4, 0.3), 22, _gem_element())
		m.set_base_angle(float(i) / float(n) * TAU)
	)


func _apply_special() -> void:  # L5 横冲直撞
	_size_mult *= 1.3
	_dmg_mult *= 1.2
