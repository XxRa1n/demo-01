class_name EnemyNormal
extends "res://scripts/enemy/enemy_base.gd"

## 普通兵：均衡型，前中期主力。红色。

const CONFIG := {
	"hp": 10.0, "speed": 60.0, "damage": 6,
	"color": Color(0.85, 0.2, 0.2), "sprite_size": 24,
	"collision_radius": 12.0, "damage_area_radius": 12.0,
	"xp_drop": 1, "show_hp_bar": false, "separation_radius": 28.0,
}


func _get_config() -> Dictionary:
	return CONFIG
