extends WeaponBase

## 矮人榴弹炮（LocatedBase·Lob）：大范围高伤爆炸 + 强击退。
## L5 发射地震炮：在目标区域持续造成伤害和减速（留一个伤害+减速地面区域）。

const projectile_scene: PackedScene = preload("res://scenes/explosive_projectile.tscn")
const GroundZone = preload("res://effects/ground_zone.gd")
const MORTAR_SPEED: float = 300.0


func _init() -> void:
	weapon_id = &"mortar"
	display_name = "矮人榴弹炮"
	weapon_icon_color = Color(0.5, 0.5, 0.55)
	base_damage = 26.0
	base_cooldown = 1.8


func _fire() -> void:
	_fire_lob(projectile_scene, MORTAR_SPEED, _calc_damage(), 100.0, 260.0)
	if _l5_active:
		# 地震炮：在最近敌人处留一个持续伤害+减速区域
		var nearest := _find_nearest_enemy()
		if nearest != null:
			var z := GroundZone.new()
			z.setup(72.0 * _size_mult, _calc_damage() * 0.4, 0.5, 4.0, DamageInfo.Element.NONE, true, self)
			z.global_position = nearest.global_position
			projectiles_container.add_child(z)


func _apply_special() -> void:  # L5 地震炮
	pass
