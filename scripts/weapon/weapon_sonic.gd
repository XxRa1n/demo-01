extends WeaponBase

## 声波（Shockwave·Pulse）：360° 扩散环，伤害 + 击退。
## L5 巨大声波 + 真实伤害（更大范围 + 额外伤害）。

const Shockwave = preload("res://effects/shockwave.gd")


func _init() -> void:
	weapon_id = &"sonic"
	display_name = "声波"
	weapon_icon_color = Color(0.8, 0.9, 1.0)
	base_damage = 10.0
	base_cooldown = 1.2


func _fire() -> void:
	var radius := 200.0 * _size_mult
	var dmg := _calc_damage()
	if _l5_active:
		radius *= 1.4   # 巨大声波
		dmg *= 1.5      # 真实伤害（无防御系统可穿透，近似为额外伤害）
	var sw := Shockwave.new()
	sw.setup(280.0, radius, dmg, 180.0 * _kb_mult)
	sw.element = _gem_element()
	sw.source_weapon = self
	sw.global_position = game_manager.player.global_position
	projectiles_container.add_child(sw)


func _apply_special() -> void:  # L5 巨大声波 + 真实伤害
	pass
