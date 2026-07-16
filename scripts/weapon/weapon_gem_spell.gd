extends WeaponBase

## 宝石法术（ProjectileBase·Spread）：大扇形多发弹幕。L5 附魔宝石特效（近似为伤害）。

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


func _apply_special() -> void:  # L5 随机附魔宝石特效
	_dmg_mult *= 1.3
