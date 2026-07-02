class_name WeaponBase
extends Node

## 武器基类：承载所有武器的通用逻辑——冷却计时、等级成长、找敌、伤害计算、容器获取。
## 子类只需覆盖：_fire()（发射逻辑）、_level_data()（返回 LEVEL_DATA）、
## _init() 里写元信息（weapon_id/display_name/weapon_icon_color/base_damage/base_cooldown）。

## 武器元信息（子类在 _init() 赋值，保证实例化即可供目录查询）
var weapon_id: StringName = &""
var display_name: String = ""
var weapon_icon_color: Color = Color(1.0, 1.0, 1.0)

## 等级（索引从 0 开始，对应 Lv.1）
var weapon_level: int = 0
var is_max_level: bool = false

## 基础属性（子类在 _init() 覆盖）
var base_damage: float = 10.0
var base_cooldown: float = 1.0

## 内部计时
var cooldown_timer: float = 0.0

## 子弹容器（惰性获取，仿 enemy_spawner 的 is_instance_valid 模式，重启后重取）
var projectiles_container: Node2D = null


func _ready() -> void:
	# 等一帧让 main 场景就绪，再取容器
	await get_tree().process_frame
	_refresh_container()


func _process(delta: float) -> void:
	# 暂停/结束守卫：升级面板 process_mode=ALWAYS 仍会跑 _process，靠 is_paused 显式拦截
	if game_manager.game_over or game_manager.is_paused:
		return
	if not game_manager.player:
		return
	if not is_instance_valid(projectiles_container):
		_refresh_container()
	if not is_instance_valid(projectiles_container):
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		cooldown_timer = base_cooldown * game_manager.player.cooldown_mult
		_fire()


## 惰性获取 Projectiles 容器
func _refresh_container() -> void:
	projectiles_container = get_node_or_null("/root/Main/GameWorld/Projectiles")


## 抽象：子类覆盖，发射逻辑
func _fire() -> void:
	pass


## 子类覆盖：返回该武器的等级数据数组
func _level_data() -> Array:
	return []


func get_current_level_data() -> Dictionary:
	var data := _level_data()
	if weapon_level >= 0 and weapon_level < data.size():
		return data[weapon_level]
	return {}


## 升级武器（返回是否成功）
func level_up() -> bool:
	if is_max_level:
		return false
	weapon_level += 1
	var data := _level_data()
	if weapon_level >= data.size() - 1:
		is_max_level = true
	return true


func get_level_display() -> String:
	return "%s Lv.%d" % [display_name, weapon_level + 1]


func get_next_level_display() -> String:
	return "%s Lv.%d → Lv.%d" % [display_name, weapon_level + 1, weapon_level + 2]


## 子类覆盖：升级卡片描述
func get_upgrade_description() -> String:
	return ""


## 公共工具：找最近敌人（原 weapon_pistol 逻辑原样上提）
func _find_nearest_enemy() -> CharacterBody2D:
	if not enemy_spawner.enemies_container:
		return null
	var nearest: CharacterBody2D = null
	var nearest_dist: float = INF
	for child in enemy_spawner.enemies_container.get_children():
		if child is CharacterBody2D and is_instance_valid(child):
			var dist: float = child.global_position.distance_to(game_manager.player.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = child
	return nearest


## 公共工具：伤害 = base_damage × mult × player.might
func _calc_damage(mult: float = 1.0) -> float:
	return base_damage * mult * game_manager.player.might
