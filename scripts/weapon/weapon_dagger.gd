extends WeaponBase

## 匕首（ProjectileBase·Rapid）：高频低伤飞刀。L5 最远射程处旋转（飞刀飞到最远处原地旋转造伤）。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const SpinDagger = preload("res://effects/spin_dagger.gd")
const DAGGER_SPEED: float = 760.0


func _init() -> void:
	weapon_id = &"dagger"
	display_name = "匕首"
	weapon_icon_color = Color(0.85, 0.85, 0.9)
	base_damage = 5.0
	base_cooldown = 0.6
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	if _l5_active:
		# 最远射程处旋转：朝最近敌人方向射出旋转匕首，飞到最远处原地旋转
		var nearest := _find_nearest_enemy()
		var dir := (nearest.global_position - game_manager.player.global_position).normalized() if nearest != null else Vector2.RIGHT
		var sd := SpinDagger.new()
		sd.setup(dir, DAGGER_SPEED, 380.0, _calc_damage(), 1.5, 42.0, _gem_element(), self)
		sd.global_position = game_manager.player.global_position
		projectiles_container.add_child(sd)
	else:
		_fire_seek_spread(projectile_scene, 1, 0.12, DAGGER_SPEED, _calc_damage(), 0)


func _apply_special() -> void:  # L5 最远射程处旋转
	pass
