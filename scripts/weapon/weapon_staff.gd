extends WeaponBase

## 棍子（SlashArea）：较窄但快的斩击。
## L5 投掷旋转：把棍子投掷出去，碰到敌人后停止原地旋转造伤+减速 3s。

const Slash = preload("res://effects/slash.gd")
const ThrownStaff = preload("res://effects/thrown_staff.gd")


func _init() -> void:
	weapon_id = &"staff"
	display_name = "棍子"
	weapon_icon_color = Color(0.75, 0.55, 0.3)
	base_damage = 12.0
	base_cooldown = 0.8


func _fire() -> void:
	var nearest := _find_nearest_enemy()
	if _l5_active:
		# 投掷旋转：投出棍子，碰敌/到最远处停止原地旋转(伤害+减速 3s)
		var dir := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
		var ts := ThrownStaff.new()
		ts.setup(dir, 520.0, 520.0, _calc_damage(), _gem_element(), self)
		ts.global_position = game_manager.player.global_position
		projectiles_container.add_child(ts)
	else:
		var facing := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
		var s := Slash.new()
		s.setup(130.0 * _size_mult, 1.4, _calc_damage(), 220.0 * _kb_mult, facing)
		s.element = _gem_element()
		s.source_weapon = self
		s.global_position = game_manager.player.global_position
		projectiles_container.add_child(s)


func _apply_special() -> void:  # L5 投掷棍子原地旋转
	pass
