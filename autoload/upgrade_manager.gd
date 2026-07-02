extends Node

## 经验 / 升级 / 武器槽 管理（autoload 单例）
## - 武器是 player 的直接子节点（WeaponBase），随 reload_current_scene 自动销毁 → 重启零清理。
## - 本单例只持有 const 目录与 xp/level 状态。

## 经验与升级状态
var xp: int = 0
var level: int = 1
var xp_to_next: int = 8  # 5 + 1*3

## 武器槽上限
const MAX_WEAPON_SLOTS: int = 4

## 武器目录：登记所有可获取武器（独立场景 root=Node+script）。
## 后续每加一把武器，在此追加一条；场景未建好前不要加，避免 acquire 时 load 失败。
const WEAPON_CATALOG: Array = [
	{
		"id": &"pistol",
		"display_name": "手枪",
		"desc": "稳定单发，穿透与弹数成长",
		"scene_path": "res://scenes/weapon_pistol.tscn",
		"node_name": "WeaponPistol",
		"icon_color": Color(1.0, 0.9, 0.2),
	},
	{
		"id": &"shotgun",
		"display_name": "霰弹枪",
		"desc": "扇形多发，贴脸爆发，远距衰减",
		"scene_path": "res://scenes/weapon_shotgun.tscn",
		"node_name": "WeaponShotgun",
		"icon_color": Color(1.0, 0.5, 0.2),
	},
	{
		"id": &"rocket",
		"display_name": "火箭炮",
		"desc": "慢速大弹，爆炸 AoE + 击退",
		"scene_path": "res://scenes/weapon_rocket.tscn",
		"node_name": "WeaponRocket",
		"icon_color": Color(0.9, 0.4, 0.4),
	},
	{
		"id": &"orbit_blade",
		"display_name": "回旋刀",
		"desc": "环绕玩家的持续切割",
		"scene_path": "res://scenes/weapon_orbit_blade.tscn",
		"node_name": "WeaponOrbitBlade",
		"icon_color": Color(0.9, 0.9, 0.9),
	},
]

## 信号
signal xp_changed(current_xp: int, needed: int, level: int)
signal level_up()


func _ready() -> void:
	xp_to_next = xp_needed_for_level(level)


## 计算升级所需经验
func xp_needed_for_level(lv: int) -> int:
	return 5 + lv * 3


## 增加经验值
func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = xp_needed_for_level(level)
		xp_changed.emit(xp, xp_to_next, level)
		level_up.emit()
	xp_changed.emit(xp, xp_to_next, level)


# ─── 天赋（被动）升级 ────────────────────────────────────────────
func _get_passive_upgrades() -> Array[Dictionary]:
	return [
		{
			"name": "力量",
			"desc": "伤害 +10%",
			"apply": func(): game_manager.player.might *= 1.1,
		},
		{
			"name": "急速",
			"desc": "攻击速度 +8%",
			"apply": func(): game_manager.player.cooldown_mult *= 0.92,
		},
		{
			"name": "生命",
			"desc": "最大生命 +20",
			"apply": func():
				game_manager.player.max_hp += 20
				game_manager.player.hp = min(game_manager.player.hp + 20, game_manager.player.max_hp),
		},
		{
			"name": "疾跑",
			"desc": "移动速度 +5%",
			"apply": func(): game_manager.player.speed *= 1.05,
		},
		{
			"name": "磁铁",
			"desc": "拾取范围 +10",
			"apply": func(): game_manager.player.pickup_range += 10.0,
		},
		{
			"name": "护甲",
			"desc": "护甲 +1",
			"apply": func(): game_manager.player.armor += 1,
		},
	]


# ─── 武器槽管理 ───────────────────────────────────────────────────
## 玩家当前持有的所有武器（遍历 player 子节点，过滤 WeaponBase）
func get_owned_weapons() -> Array:
	var result: Array = []
	if not game_manager.player:
		return result
	for child in game_manager.player.get_children():
		if child is WeaponBase:
			result.append(child)
	return result


func get_owned_weapon_ids() -> Array:
	var ids: Array = []
	for w in get_owned_weapons():
		ids.append(w.weapon_id)
	return ids


func get_free_slots() -> int:
	return MAX_WEAPON_SLOTS - get_owned_weapons().size()


func _get_catalog_entry(id: StringName) -> Dictionary:
	for entry in WEAPON_CATALOG:
		if entry["id"] == id:
			return entry
	return {}


func _has_unowned_in_catalog() -> bool:
	var owned := get_owned_weapon_ids()
	for entry in WEAPON_CATALOG:
		if not owned.has(entry["id"]):
			return true
	return false


## 获取一把新武器（调用前应已有空槽且未持有）
func acquire_weapon(id: StringName) -> WeaponBase:
	var entry: Dictionary = _get_catalog_entry(id)
	if entry.is_empty():
		return null
	if get_free_slots() <= 0:
		return null
	var scene: PackedScene = load(entry["scene_path"])
	var node = scene.instantiate()
	if node is WeaponBase:
		node.name = entry["node_name"]
		game_manager.player.add_child(node)
		return node
	return null


## 丢弃并销毁一把武器
func remove_weapon(node: WeaponBase) -> void:
	if is_instance_valid(node):
		node.get_parent().remove_child(node)
		node.queue_free()


# ─── 升级选项生成 ─────────────────────────────────────────────────
## 武器步骤三选一池：新武器获取卡 ∪ 已持有升级卡 ∪ 已持有丢弃卡
func get_weapon_choices(count: int) -> Array:
	var pool: Array = []
	var owned := get_owned_weapons()
	var owned_ids := get_owned_weapon_ids()

	# 1. 新武器获取卡（仅当有空槽）
	if get_free_slots() > 0:
		for entry in WEAPON_CATALOG:
			if not owned_ids.has(entry["id"]):
				pool.append(_make_acquire_card(entry))
	# 2. 已持有未满级武器的升级卡
	for w in owned:
		if not w.is_max_level:
			pool.append(_make_upgrade_card(w))
	# 3. 已持有武器的丢弃卡
	for w in owned:
		pool.append(_make_discard_card(w))

	return _pick_random(pool, count)


## 天赋步骤三选一：6 个被动
func get_talent_choices(count: int) -> Array:
	return _pick_random(_get_passive_upgrades(), count)


## 武器步骤是否应自动跳过：无新武器可获取 且 无武器可升级（丢弃卡不阻止跳过）
func should_skip_weapon_step() -> bool:
	var no_acquire: bool = get_free_slots() == 0 or not _has_unowned_in_catalog()
	var no_upgrade: bool = true
	for w in get_owned_weapons():
		if not w.is_max_level:
			no_upgrade = false
			break
	return no_acquire and no_upgrade


## 工厂函数：隔离闭包捕获，避免 for 循环里 lambda 共享循环变量的最终值
func _make_acquire_card(entry: Dictionary) -> Dictionary:
	var id: StringName = entry["id"]
	return {
		"name": "获得 " + String(entry["display_name"]),
		"desc": String(entry["desc"]),
		"apply": func(): acquire_weapon(id),
	}


func _make_upgrade_card(w: WeaponBase) -> Dictionary:
	return {
		"name": w.get_next_level_display(),
		"desc": w.get_upgrade_description(),
		"apply": func(): w.level_up(),
	}


func _make_discard_card(w: WeaponBase) -> Dictionary:
	return {
		"name": "丢弃 " + w.display_name,
		"desc": "腾出一个武器槽",
		"apply": func(): remove_weapon(w),
	}


## 从池中随机抽取 count 个不重复项（池不够时循环复用）
func _pick_random(pool: Array, count: int) -> Array:
	var result: Array = []
	if pool.is_empty():
		return result
	var available: Array = pool.duplicate()
	for _i in count:
		if available.is_empty():
			available = pool.duplicate()
		var idx: int = randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)
	return result
