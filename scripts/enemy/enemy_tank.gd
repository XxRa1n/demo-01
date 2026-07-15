class_name EnemyTank
extends "res://scripts/enemy/enemy_base.gd"

## 坦克：慢、肉、大、带血条，吸收火力。灰色。

const CONFIG := {
	"hp": 55.0, "speed": 35.0, "damage": 12,
	"color": Color(0.35, 0.35, 0.45), "sprite_size": 40,
	"collision_radius": 20.0, "damage_area_radius": 22.0,
	"xp_drop": 5, "show_hp_bar": true, "separation_radius": 44.0,
		"tier": "elite",
}


func _get_config() -> Dictionary:
	return CONFIG
