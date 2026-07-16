extends WeaponBase

## 竖琴（ProjectileBase·特殊）：随机方向发射「音符」。L5 do-re-mi（多发）。

const projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
const NOTE_SPEED: float = 560.0


func _init() -> void:
	weapon_id = &"harp"
	display_name = "竖琴"
	weapon_icon_color = Color(0.95, 0.6, 0.9)
	base_damage = 9.0
	base_cooldown = 1.0
	_count_supported = true
	_pierce_supported = true


func _fire() -> void:
	var n := 1 + _count_bonus
	var dmg := _calc_damage()
	var pierce := _pierce_bonus
	var speed := NOTE_SPEED * _size_mult
	var el := _gem_element()
	for _i in n:
		var dir := Vector2.from_angle(randf() * TAU)
		var proj := projectile_scene.instantiate()
		proj.setup(dmg, speed, dir, pierce, el, self)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)


func _apply_special() -> void:  # L5 do re mi 圆形范围（近似多发）
	_count_bonus += 2
