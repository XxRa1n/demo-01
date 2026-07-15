class_name EnemyShooter
extends "res://scripts/enemy/enemy_base.gd"

## 远程兵：保持射程风筝玩家 + 周期发射大而慢的子弹。青色。
## 这是唯一需要独特「行为」的敌人，故覆盖基类两个钩子：
##   _get_seek_dir → 太近则后撤（风筝）
##   _tick_behavior → 倒计时到点发射子弹
## 远程相关字段、子弹发射逻辑全部收在本文件，基类不含任何远程代码。

const CONFIG := {
	"hp": 14.0, "speed": 50.0, "damage": 6,
	"color": Color(0.2, 0.75, 0.95), "sprite_size": 22,
	"collision_radius": 11.0, "damage_area_radius": 12.0,
	"xp_drop": 2, "show_hp_bar": false, "separation_radius": 26.0,
	# 远程：风筝走位 + 周期发射大慢子弹（子弹伤害随 stat_scale 缩放）
	"shoot_interval": 2.4, "shoot_range": 460.0,
	"preferred_range": 280.0, "proj_speed": 130.0, "proj_damage": 10,
	"proj_radius": 14.0, "first_shot_delay": 0.8,
}

## 远程开火参数（setup 时从 CONFIG 读取）
var shoot_interval: float = 2.0
var shoot_range: float = 400.0
var preferred_range: float = 250.0
var proj_speed: float = 130.0
var proj_damage: int = 10
var proj_radius: float = 14.0
var _shoot_timer: float = 0.0
var _projectiles_container: Node2D = null

const enemy_projectile_scene: PackedScene = preload("res://effects/enemy_projectile.tscn")


func _get_config() -> Dictionary:
	return CONFIG


func setup(p_stat_scale: float = 1.0) -> void:
	super(p_stat_scale)  # 先读共用字段（hp/速度/外观/碰撞…）
	var c: Dictionary = CONFIG
	shoot_interval = float(c.get("shoot_interval", 2.0))
	shoot_range = float(c.get("shoot_range", 400.0))
	preferred_range = float(c.get("preferred_range", 250.0))
	proj_speed = float(c.get("proj_speed", 130.0))
	proj_damage = int(round(float(c.get("proj_damage", 10)) * p_stat_scale))  # 随波次缩放
	proj_radius = float(c.get("proj_radius", 14.0))
	_shoot_timer = float(c.get("first_shot_delay", 0.8))
	# 注意：这里不去取 Projectiles 容器。setup() 由生成器在 add_child 之前调用，
	# 此时敌人尚未进入场景树，用绝对路径 get_node 会报错。容器在 _fire_projectile
	# 发射时（敌人已在树中）惰性重取即可，见 _fire_projectile。


## 风筝：进入 preferred_range 后改为后撤，保持射程。
func _get_seek_dir(to_player: Vector2, dist: float) -> Vector2:
	if dist <= 0.001:
		return Vector2.RIGHT
	var dir := to_player.normalized()
	if dist < preferred_range:
		dir = -dir
	return dir


## 周期开火：进入射程且计时到点时，朝玩家发射大而慢的子弹。
func _tick_behavior(delta: float, dist: float, to_player: Vector2) -> void:
	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and dist <= shoot_range:
		_shoot_timer = shoot_interval
		var fire_dir := to_player.normalized() if dist > 0.001 else Vector2.RIGHT
		_fire_projectile(fire_dir)


## 发射一颗子弹（加入 Projectiles 容器，与玩家子弹同池）。
func _fire_projectile(dir: Vector2) -> void:
	if not is_instance_valid(_projectiles_container):
		_projectiles_container = get_node_or_null("/root/Main/GameWorld/Projectiles")
	if not is_instance_valid(_projectiles_container):
		return
	var proj: Area2D = enemy_projectile_scene.instantiate()
	proj.setup(proj_damage, proj_speed, dir, proj_radius)
	proj.global_position = global_position
	_projectiles_container.add_child(proj)
