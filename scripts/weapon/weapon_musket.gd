extends WeaponBase

## 火枪（ProjectileBase·Seek）：单发高伤远程射击。L5 向空中发射子弹，子弹从空中掉落随机砸敌。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const FallingStrike = preload("res://effects/falling_strike.gd")
const MUSKET_SPEED: float = 900.0


func _init() -> void:
	weapon_id = &"musket"
	display_name = "火枪"
	weapon_icon_color = Color(0.3, 0.3, 0.3)
	base_damage = 22.0
	base_cooldown = 1.4
	_pierce_supported = true


func _fire() -> void:
	if _l5_active:
		# 空中掉落：朝多个随机敌人头顶投下落弹
		var n: int = 3 + _count_bonus
		var el := _gem_element()
		for _i in n:
			var t = _random_enemy_pos()
			if t == null:
				return
			var fs := FallingStrike.new()
			fs.setup(t, _calc_damage(), 42.0 * _size_mult, el, self)
			fs.global_position = t + Vector2(0.0, -260.0)
			projectiles_container.add_child(fs)
	else:
		_fire_seek_spread(projectile_scene, 1, 0.0, MUSKET_SPEED, _calc_damage(), 0)


func _apply_special() -> void:  # L5 向空中发射子弹掉落
	pass  # 行为由 _l5_active 分支驱动
