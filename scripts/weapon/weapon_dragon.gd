extends WeaponBase

## 龙（Minion·Follower）：跟随的吐息 AoE，附燃烧。
## L5 随机喷射三条火焰（1 条龙改为喷 3 道火，非多条龙）。

const Minion = preload("res://effects/minion.gd")


func _init() -> void:
	weapon_id = &"dragon"
	display_name = "龙"
	weapon_icon_color = Color(0.95, 0.4, 0.3)
	base_damage = 14.0
	base_cooldown = 0.5
	# 龙 L5 是攻击行为(三条火焰)，不增加龙的数量 → 不支持数量词条，始终 1 条龙


func _fire() -> void:
	var dmg := _calc_damage()
	var kind: String = "triple_flame" if _l5_active else "aoe"
	_sync_minions(func(): return Minion.new(), 1, func(m, i, n):
		m.setup(66.0, 2.2, 170.0 * _size_mult, 1.0, 52.0 * _size_mult, dmg, kind, Color(0.95, 0.4, 0.3), 18, DamageInfo.Element.FIRE)
		m.set_base_angle(float(i) / float(n) * TAU)
	)


func _apply_special() -> void:  # L5 随机喷射三条火焰（行为由 _l5_active 驱动）
	pass
