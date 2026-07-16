extends WeaponBase

## 喷火（Shockwave·扇形 + 火）：朝最近敌人喷火锥，附燃烧。
## L5 短 charge，每隔一段时间在地上喷射圆形岩浆区域（持续燃烧 + 减速）。

const Shockwave = preload("res://effects/shockwave.gd")
const GroundZone = preload("res://effects/ground_zone.gd")
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
	# L5 岩浆区域：在最近敌人处留一个燃烧地面
	if _l5_active and nearest != null:
		var z := GroundZone.new()
		z.setup(52.0 * _size_mult, _calc_damage() * 0.3, 0.5, 5.0, DamageInfo.Element.FIRE, false, self)
		z.global_position = nearest.global_position
		projectiles_container.add_child(z)


func _apply_special() -> void:  # L5 地上岩浆区域
	pass
