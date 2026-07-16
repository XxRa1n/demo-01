extends WeaponBase

## 棍子（SlashArea）：较窄但快的斩击。
## L5 投掷棍子：棍子飞到目标处原地旋转造成伤害+减速（近似为在目标处留一个伤害+减速地面区域 3s）。

const Slash = preload("res://effects/slash.gd")
const GroundZone = preload("res://effects/ground_zone.gd")


func _init() -> void:
	weapon_id = &"staff"
	display_name = "棍子"
	weapon_icon_color = Color(0.75, 0.55, 0.3)
	base_damage = 12.0
	base_cooldown = 0.8


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
	var s := Slash.new()
	s.setup(130.0 * _size_mult, 1.4, _calc_damage(), 220.0 * _kb_mult, facing)
	s.element = _gem_element()
	s.source_weapon = self
	s.global_position = game_manager.player.global_position
	projectiles_container.add_child(s)
	if _l5_active and nearest != null:
		# 投掷旋转：在目标处留 3s 伤害+减速区域
		var z := GroundZone.new()
		z.setup(58.0 * _size_mult, _calc_damage() * 0.4, 0.4, 3.0, DamageInfo.Element.NONE, true, self)
		z.global_position = nearest.global_position
		projectiles_container.add_child(z)


func _apply_special() -> void:  # L5 投掷棍子原地旋转
	pass
