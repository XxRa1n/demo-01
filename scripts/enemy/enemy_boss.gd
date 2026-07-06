class_name EnemyBoss
extends "res://scripts/enemy/enemy_base.gd"

## Boss：超大、超肉、带血条，仅由 BOSS_WAVES 强制刷出。紫色。

const CONFIG := {
	"hp": 600.0, "speed": 28.0, "damage": 25,
	"color": Color(0.55, 0.1, 0.7), "sprite_size": 72,
	"collision_radius": 38.0, "damage_area_radius": 42.0,
	"xp_drop": 50, "show_hp_bar": true, "separation_radius": 80.0,
}


func _get_config() -> Dictionary:
	return CONFIG
