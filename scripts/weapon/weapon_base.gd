class_name WeaponBase
extends Node

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

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

## 环绕实体缓存（OrbitEntity 类武器用：旋转飞斧 / 环绕圣经）
var _orbit_blades: Array = []

## 召唤物缓存（Minion 类武器用：炮台 / 猫 / 龙 / 熊）
var _minions: Array = []

## 宝石槽：gem_slots[i] = gem_id(StringName) 或 null。max_gem_slots 为可用槽位（基础 1，满级 +2）。
var gem_slots: Array = []
var max_gem_slots: int = 1
## 本帧开火参数缓存（_process 在 _fire 前写入；_fire / 各 helper 读取）
var _params: Dictionary = {}


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
		var lv := get_current_level_data()
		var cd_mult: float = float(lv.get("cd", 1.0))  # 等级成长里的攻速/减cd
		_params = _compute_fire_params()  # 缓存本帧宝石派生参数（元素 / 连击 / 技能cd）
		var cd := base_cooldown
		if float(_params.get("cooldown_override", 0.0)) > 0.0:  # 技能cd 宝石：固定冷却 = base - 1
			cd = float(_params["cooldown_override"])
		cooldown_timer = cd * cd_mult * game_manager.player.cooldown_mult
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
		max_gem_slots += 2  # 满级(L8) 解锁 +2 宝石槽
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


## 通用：朝最近敌人发射一组扇形扩散的直线子弹（ProjectileBase 类武器共用）。
## count=1 时无扩散；元素与来源武器随子弹带入 DamageInfo；连击宝石让整组齐射多次。
func _fire_seek_spread(scene: PackedScene, count: int, spread: float, speed: float, dmg: float, pierce: int, element: int = DamageInfo.Element.NONE) -> void:
	var nearest := _find_nearest_enemy()
	if nearest == null:
		return
	var el: int = _gem_element(element)
	var volleys: int = _gem_attack_count()
	var base_dir := (nearest.global_position - game_manager.player.global_position).normalized()
	var start: float = -spread * float(count - 1) / 2.0
	for _v in volleys:  # 连击 / 2020 宝石：整组齐射多次
		for i in count:
			var dir := base_dir.rotated(start + spread * float(i)) if count > 1 else base_dir
			var proj := scene.instantiate()
			proj.setup(dmg, speed, dir, pierce, el, self)
			proj.global_position = game_manager.player.global_position
			projectiles_container.add_child(proj)


## 通用：朝最近敌人发射一枚爆炸弹（LocatedBase 类武器共用）。连击宝石多发齐投。
func _fire_lob(scene: PackedScene, speed: float, dmg: float, blast: float, knockback: float) -> void:
	var nearest := _find_nearest_enemy()
	if nearest == null:
		return
	var el: int = _gem_element()
	var volleys: int = _gem_attack_count()
	var dir := (nearest.global_position - game_manager.player.global_position).normalized()
	for _v in volleys:
		var proj := scene.instantiate()
		proj.setup(dmg, speed, dir, blast, knockback, el, self)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)


## 通用：维持 N 个环绕实体（OrbitEntity 类武器共用）。幂等同步数量与参数；元素取自宝石。
func _sync_orbit_blades(blade_scene: PackedScene, count: int, radius: float, speed: float, dmg: float, element: int = DamageInfo.Element.NONE) -> void:
	if not is_instance_valid(projectiles_container):
		return
	while _orbit_blades.size() < count:
		var b := blade_scene.instantiate()
		projectiles_container.add_child(b)
		_orbit_blades.append(b)
	while _orbit_blades.size() > count:
		var extra = _orbit_blades.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()
	var el: int = _gem_element(element)
	for i in _orbit_blades.size():
		var base_angle: float = (float(i) / float(max(_orbit_blades.size(), 1))) * TAU
		_orbit_blades[i].set_params(radius, speed, base_angle, dmg, el, self)


## 通用：维持 N 个召唤物（Minion 类武器共用）。幂等同步数量；setup_fn 负责逐个配置（含 base_angle）。
## factory: 返回一个新 Minion 实例的 Callable（minion 无 .tscn，用 Minion.new()）。
func _sync_minions(factory: Callable, count: int, setup_fn: Callable) -> void:
	if not is_instance_valid(projectiles_container):
		return
	while _minions.size() < count:
		var m = factory.call()
		projectiles_container.add_child(m)
		_minions.append(m)
	while _minions.size() > count:
		var extra = _minions.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()
	var n: int = max(_minions.size(), 1)
	for i in _minions.size():
		setup_fn.call(_minions[i], i, n)


# ─── 宝石系统 ─────────────────────────────────────────────
## 由已镶嵌宝石派生的开火参数（连击数 / 元素 / 冷却覆盖 / 击退倍率）。
func _compute_fire_params() -> Dictionary:
	var p := {"attack_count": 1, "element": DamageInfo.Element.NONE, "cooldown_override": 0.0, "knockback_mult": 1.0}
	for gem_id in gem_slots:
		if gem_id == null:
			continue
		match gem_id:
			&"double_strike", &"2020":
				p["attack_count"] = int(p["attack_count"]) + 1
			&"skill_cd":
				p["cooldown_override"] = maxf(float(p["cooldown_override"]), maxf(base_cooldown - 1.0, 0.2))
			&"knockback":
				p["knockback_mult"] = float(p["knockback_mult"]) * 1.5
			&"fire":
				p["element"] = DamageInfo.Element.FIRE
			&"water":
				p["element"] = DamageInfo.Element.WATER
			&"ice":
				p["element"] = DamageInfo.Element.ICE
			&"lightning":
				p["element"] = DamageInfo.Element.LIGHTNING
			&"grass":
				p["element"] = DamageInfo.Element.GRASS
	return p


## 取本帧宝石派生元素（无宝石时回退 fallback）。
func _gem_element(fallback: int = DamageInfo.Element.NONE) -> int:
	if _params.is_empty():
		return fallback
	return int(_params.get("element", fallback))


## 取本帧宝石派生连击数（无宝石时 1）。
func _gem_attack_count() -> int:
	if _params.is_empty():
		return 1
	return int(_params.get("attack_count", 1))


## 镶嵌宝石到指定槽位（覆盖原有）。全局宝石立即生效到玩家；fire_mod/元素宝石随 _compute_fire_params 生效。
func socket_gem(slot: int, gem_id: StringName) -> bool:
	if slot < 0 or slot >= max_gem_slots:
		return false
	while gem_slots.size() <= slot:
		gem_slots.append(null)
	if gem_slots[slot] != null:
		_revert_gem(gem_slots[slot])
	gem_slots[slot] = gem_id
	_apply_gem(gem_id)
	return true


## 拆下槽位宝石，返回原宝石 id。
func unsocket_gem(slot: int) -> Variant:
	if slot < 0 or slot >= gem_slots.size():
		return null
	var old = gem_slots[slot]
	if old != null:
		_revert_gem(old)
	gem_slots[slot] = null
	return old


func _apply_gem(gem_id: Variant) -> void:
	if gem_id == null or game_manager == null or not is_instance_valid(game_manager.player):
		return
	var p = game_manager.player
	if gem_registry.is_global_apply(gem_id):
		gem_registry.apply_global(gem_id, p)
	elif gem_registry.is_flag(gem_id):
		gem_registry.apply_flag(gem_id, p)


func _revert_gem(gem_id: Variant) -> void:
	if gem_id == null or game_manager == null or not is_instance_valid(game_manager.player):
		return
	var p = game_manager.player
	if gem_registry.is_global_apply(gem_id):
		gem_registry.revert_global(gem_id, p)
	elif gem_registry.is_flag(gem_id):
		gem_registry.revert_flag(gem_id, p)
