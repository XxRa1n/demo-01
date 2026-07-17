extends WeaponBase

## 猫（Minion·Follower）：跟随的快速近战 AoE。L5 分身持续 10s（周期性临时多 2 只）。

const Minion = preload("res://effects/minion.gd")


func _init() -> void:
	weapon_id = &"cat"
	display_name = "猫"
	weapon_icon_color = Color(0.9, 0.7, 0.4)
	base_damage = 6.0
	base_cooldown = 0.5
	# 猫数量只由 L5 分身(临时)提供，不走数量词条


func _fire() -> void:
	# L5 分身：周期性临时 +2 只，持续 10s，冷却 15s（即 10s 三猫 + 5s 一猫 循环）
	if _l5_active and not _buff_active and _buff_cd <= 0.0:
		_start_buff(1.0, 1.0, 2, 10.0)
		_buff_cd = 15.0
	var dmg := _calc_damage()
	_sync_minions(func(): return Minion.new(), 1, func(m, i, n):
		m.setup(58.0, 3.0, 150.0 * _size_mult, 0.5, 36.0 * _size_mult, dmg, "aoe", Color(0.9, 0.7, 0.4), 12, _gem_element())
		m.set_base_angle(float(i) / float(n) * TAU)
	)


func _apply_special() -> void:  # L5 分身持续 10s
	pass
