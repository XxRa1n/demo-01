extends WeaponBase

## 回旋镖（ProjectileBase·Seek）：高速穿透飞镖（折返待精修）。
## L5 黄金回旋：以自身为中心、按黄金角间隔打出多向飞镖，飞出后呈螺旋纹理。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const BOOMERANG_SPEED: float = 520.0
const BASE_PIERCE: int = 2
const GOLDEN_ANGLE: float = 2.399963  # 137.5° 黄金角


func _init() -> void:
	weapon_id = &"boomerang"
	display_name = "回旋镖"
	weapon_icon_color = Color(0.95, 0.75, 0.2)
	base_damage = 9.0
	base_cooldown = 1.2
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	if _l5_active:
		var n: int = 8 + _count_bonus * 2
		var ang: float = 0.0
		var dmg := _calc_damage()
		var pierce: int = 3 + _pierce_bonus
		var speed := BOOMERANG_SPEED * _size_mult
		var el := _gem_element()
		for _i in n:
			var dir := Vector2.from_angle(ang)
			var proj := projectile_scene.instantiate()
			proj.setup(dmg, speed, dir, pierce, el, self)
			proj.global_position = game_manager.player.global_position
			projectiles_container.add_child(proj)
			ang += GOLDEN_ANGLE
	else:
		_fire_seek_spread(projectile_scene, 1, 0.25, BOOMERANG_SPEED, _calc_damage(), BASE_PIERCE)


func _apply_special() -> void:  # L5 黄金回旋
	pass
