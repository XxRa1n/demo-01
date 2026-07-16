extends WeaponBase

## 声波（Shockwave·Pulse）：360° 扩散环，伤害 + 击退。L5 巨大声波 + 真实伤害。

const Shockwave = preload("res://effects/shockwave.gd")


func _init() -> void:
	weapon_id = &"sonic"
	display_name = "声波"
	weapon_icon_color = Color(0.8, 0.9, 1.0)
	base_damage = 10.0
	base_cooldown = 1.2


func _fire() -> void:
	var sw := Shockwave.new()
	sw.setup(280.0, 200.0 * _size_mult, _calc_damage(), 180.0 * _kb_mult)
	sw.element = _gem_element()
	sw.source_weapon = self
	sw.global_position = game_manager.player.global_position
	projectiles_container.add_child(sw)


func _apply_special() -> void:  # L5 巨大声波 + 真实伤害
	_size_mult *= 1.2
	_dmg_mult *= 1.4
