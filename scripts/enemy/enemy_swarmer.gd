class_name EnemySwarmer
extends "res://scripts/enemy/enemy_base.gd"

## 群蜂：速度快、血薄、体型小，靠数量压人。橙色。

const CONFIG := {
	"hp": 3.0, "speed": 110.0, "damage": 3,
	"color": Color(0.9, 0.5, 0.2), "sprite_size": 14,
	"collision_radius": 7.0, "damage_area_radius": 8.0,
	"xp_drop": 1, "show_hp_bar": false, "separation_radius": 18.0,
}


func _get_config() -> Dictionary:
	return CONFIG
