extends WeaponBase

## 猫（Minion·Follower）：跟随的快速近战 AoE。L5 分身（数量 +2）。

const Minion = preload("res://effects/minion.gd")


func _init() -> void:
	weapon_id = &"cat"
	display_name = "猫"
	weapon_icon_color = Color(0.9, 0.7, 0.4)
	base_damage = 6.0
	base_cooldown = 0.5
	_count_supported = true


func _fire() -> void:
	var dmg := _calc_damage()
	_sync_minions(func(): return Minion.new(), 1, func(m, i, n):
		m.setup(58.0, 3.0, 150.0 * _size_mult, 0.5, 36.0 * _size_mult, dmg, "aoe", Color(0.9, 0.7, 0.4), 12, _gem_element())
		m.set_base_angle(float(i) / float(n) * TAU)
	)


func _apply_special() -> void:  # L5 分身
	_count_bonus += 2
