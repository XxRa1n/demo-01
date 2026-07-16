extends WeaponBase

## 龙（Minion·Follower）：跟随的吐息 AoE，附燃烧。L5 三条火焰（数量 +2）。

const Minion = preload("res://effects/minion.gd")


func _init() -> void:
	weapon_id = &"dragon"
	display_name = "龙"
	weapon_icon_color = Color(0.95, 0.4, 0.3)
	base_damage = 14.0
	base_cooldown = 0.5
	_count_supported = true


func _fire() -> void:
	var dmg := _calc_damage()
	_sync_minions(func(): return Minion.new(), 1, func(m, i, n):
		m.setup(66.0, 2.2, 170.0 * _size_mult, 1.0, 52.0 * _size_mult, dmg, "aoe", Color(0.95, 0.4, 0.3), 18, _gem_element(DamageInfo.Element.FIRE))
		m.set_base_angle(float(i) / float(n) * TAU)
	)


func _apply_special() -> void:  # L5 随机喷射三条火焰
	_count_bonus += 2
