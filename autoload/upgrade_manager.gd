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

## 武器目录：登记所有可获取武器（每把武器 = 一个 WeaponBase 脚本，acquire 时用 script.new() 实例化）。
## 仅保留 宝石.md 定义的行为原语武器。
const WEAPON_CATALOG: Array = [
	{
		"id": &"bow",
		"display_name": "弓箭",
		"desc": "扇形多发箭矢，弹数与伤害成长",
		"script_path": "res://scripts/weapon/weapon_bow.gd",
		"node_name": "WeaponBow",
		"icon_color": Color(0.6, 0.4, 0.2),
	},
	{
		"id": &"crossbow",
		"display_name": "弩箭",
		"desc": "单发高伤穿透弩矢",
		"script_path": "res://scripts/weapon/weapon_crossbow.gd",
		"node_name": "WeaponCrossbow",
		"icon_color": Color(0.45, 0.3, 0.15),
	},
	{
		"id": &"dagger",
		"display_name": "匕首",
		"desc": "高频低伤飞刀，攻速成长",
		"script_path": "res://scripts/weapon/weapon_dagger.gd",
		"node_name": "WeaponDagger",
		"icon_color": Color(0.85, 0.85, 0.9),
	},
	{
		"id": &"boomerang",
		"display_name": "回旋镖",
		"desc": "高速穿透飞镖",
		"script_path": "res://scripts/weapon/weapon_boomerang.gd",
		"node_name": "WeaponBoomerang",
		"icon_color": Color(0.95, 0.75, 0.2),
	},
	{
		"id": &"musket",
		"display_name": "火枪",
		"desc": "单发高伤远程射击",
		"script_path": "res://scripts/weapon/weapon_musket.gd",
		"node_name": "WeaponMusket",
		"icon_color": Color(0.3, 0.3, 0.3),
	},
	{
		"id": &"harp",
		"display_name": "竖琴",
		"desc": "随机方向发射音符",
		"script_path": "res://scripts/weapon/weapon_harp.gd",
		"node_name": "WeaponHarp",
		"icon_color": Color(0.95, 0.6, 0.9),
	},
	{
		"id": &"gem_spell",
		"display_name": "宝石法术",
		"desc": "大扇形多发弹幕",
		"script_path": "res://scripts/weapon/weapon_gem_spell.gd",
		"node_name": "WeaponGemSpell",
		"icon_color": Color(0.6, 0.85, 1.0),
	},
	{
		"id": &"holy_water",
		"display_name": "圣水瓶",
		"desc": "投掷爆炸 AoE + 击退",
		"script_path": "res://scripts/weapon/weapon_holy_water.gd",
		"node_name": "WeaponHolyWater",
		"icon_color": Color(0.7, 0.85, 1.0),
	},
	{
		"id": &"mortar",
		"display_name": "矮人榴弹炮",
		"desc": "大范围高伤爆炸 + 强击退",
		"script_path": "res://scripts/weapon/weapon_mortar.gd",
		"node_name": "WeaponMortar",
		"icon_color": Color(0.5, 0.5, 0.55),
	},
	{
		"id": &"laser",
		"display_name": "激光",
		"desc": "锁定最近敌人的持续光束，按帧 DPS",
		"script_path": "res://scripts/weapon/weapon_laser.gd",
		"node_name": "WeaponLaser",
		"icon_color": Color(0.4, 0.8, 1.0),
	},
	{
		"id": &"sonic",
		"display_name": "声波",
		"desc": "360° 扩散环，伤害 + 击退",
		"script_path": "res://scripts/weapon/weapon_sonic.gd",
		"node_name": "WeaponSonic",
		"icon_color": Color(0.8, 0.9, 1.0),
	},
	{
		"id": &"flamethrower",
		"display_name": "喷火",
		"desc": "朝最近敌人喷火锥，附燃烧",
		"script_path": "res://scripts/weapon/weapon_flamethrower.gd",
		"node_name": "WeaponFlamethrower",
		"icon_color": Color(1.0, 0.5, 0.2),
	},
	{
		"id": &"spinning_axe",
		"display_name": "旋转飞斧",
		"desc": "环绕玩家旋转的持续切割",
		"script_path": "res://scripts/weapon/weapon_spinning_axe.gd",
		"node_name": "WeaponSpinningAxe",
		"icon_color": Color(0.9, 0.7, 0.3),
	},
	{
		"id": &"holy_book",
		"display_name": "环绕圣经",
		"desc": "环绕玩家的圣典，持续命中",
		"script_path": "res://scripts/weapon/weapon_holy_book.gd",
		"node_name": "WeaponHolyBook",
		"icon_color": Color(0.95, 0.92, 0.6),
	},
	{
		"id": &"sword",
		"display_name": "长剑",
		"desc": "瞬时扇形斩击 + 强击退",
		"script_path": "res://scripts/weapon/weapon_sword.gd",
		"node_name": "WeaponSword",
		"icon_color": Color(0.9, 0.9, 0.95),
	},
	{
		"id": &"greatsword",
		"display_name": "巨剑",
		"desc": "更宽更大的斩击，高伤慢速",
		"script_path": "res://scripts/weapon/weapon_greatsword.gd",
		"node_name": "WeaponGreatsword",
		"icon_color": Color(0.7, 0.7, 0.8),
	},
	{
		"id": &"staff",
		"display_name": "棍子",
		"desc": "较窄但快的斩击",
		"script_path": "res://scripts/weapon/weapon_staff.gd",
		"node_name": "WeaponStaff",
		"icon_color": Color(0.75, 0.55, 0.3),
	},
	{
		"id": &"turret",
		"display_name": "炮台",
		"desc": "环绕炮台，自动发射直射弹",
		"script_path": "res://scripts/weapon/weapon_turret.gd",
		"node_name": "WeaponTurret",
		"icon_color": Color(0.5, 0.5, 0.6),
	},
	{
		"id": &"cat",
		"display_name": "猫",
		"desc": "跟随的快速近战 AoE",
		"script_path": "res://scripts/weapon/weapon_cat.gd",
		"node_name": "WeaponCat",
		"icon_color": Color(0.9, 0.7, 0.4),
	},
	{
		"id": &"dragon",
		"display_name": "龙",
		"desc": "跟随的吐息 AoE，附燃烧",
		"script_path": "res://scripts/weapon/weapon_dragon.gd",
		"node_name": "WeaponDragon",
		"icon_color": Color(0.95, 0.4, 0.3),
	},
	{
		"id": &"bear",
		"display_name": "熊",
		"desc": "跟随的重型大范围 AoE",
		"script_path": "res://scripts/weapon/weapon_bear.gd",
		"node_name": "WeaponBear",
		"icon_color": Color(0.5, 0.4, 0.3),
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
## 用 script.new() 实例化（武器脚本 extends WeaponBase extends Node，_init 设元信息、_ready 取容器）。
func acquire_weapon(id: StringName) -> WeaponBase:
	var entry: Dictionary = _get_catalog_entry(id)
	if entry.is_empty():
		return null
	if get_free_slots() <= 0:
		return null
	var script = load(entry["script_path"])
	var node = script.new()
	if node is WeaponBase:
		node.name = entry["node_name"]
		game_manager.player.add_child(node)
		node.set_process(true)  # script.new() 实例化的节点防御性显式启用 _process
		return node
	if is_instance_valid(node):
		node.queue_free()
	return null


# ─── 升级选项生成 ─────────────────────────────────────────────────
## 武器步骤三选一池：新武器获取卡 ∪ 已持有升级卡（无丢弃选项）
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

	return _pick_random(pool, count)


## 天赋步骤三选一：6 个被动
func get_talent_choices(count: int) -> Array:
	return _pick_random(_get_passive_upgrades(), count)


## 武器步骤是否应自动跳过：无新武器可获取 且 无武器可升级
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
