extends WeaponBase

## 喷火（Shockwave·扇形 + 火）：朝最近敌人喷火锥，附燃烧。L5 地上岩浆区域（更大范围）。

const Shockwave = preload("res://effects/shockwave.gd")
const ARC: float = 1.4  # ~80° 火锥


func _init() -> void:
	weapon_id = &"flamethrower"
	display_name = "喷火"
	weapon_icon_color = Color(1.0, 0.5, 0.2)
	base_damage = 8.0
	base_cooldown = 1.1


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var sw := Shockwave.new()
	sw.setup(320.0, 170.0 * _size_mult, _calc_damage(), 0.0, ARC, facing, DamageInfo.Element.FIRE, self)
	sw.global_position = game_manager.player.global_position
	projectiles_container.add_child(sw)


func _apply_special() -> void:  # L5 地上岩浆区域
	_size_mult *= 1.3
