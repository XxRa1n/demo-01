extends WeaponBase

## 宝石法术（ProjectileBase·Spread）：大扇形多发弹幕。L5 随机给武器附魔一个宝石特效持续 10s。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const SPELL_SPEED: float = 540.0
const SPREAD: float = 0.55


func _init() -> void:
	weapon_id = &"gem_spell"
	display_name = "宝石法术"
	weapon_icon_color = Color(0.6, 0.85, 1.0)
	base_damage = 5.0
	base_cooldown = 1.2
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	_fire_seek_spread(projectile_scene, 5, SPREAD, SPELL_SPEED, _calc_damage(), 0)
	# L5 附魔：附魔过期后随机续一个元素 10s（_compute_fire_params 据此改命中元素）
	if _l5_active and _enchant_timer <= 0.0:
		_roll_enchant()


func _apply_special() -> void:  # L5 随机附魔宝石特效 10s
	pass
