extends Node

## 经验与升级状态
var xp: int = 0
var level: int = 1
var xp_to_next: int = 8  # 5 + 1*3

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


## 被动升级定义
## 每个包含: name, desc, apply (Callable)
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


## 生成随机升级选项（不重复）
func get_upgrade_choices(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	# 添加所有被动升级
	pool.append_array(_get_passive_upgrades())

	# 如果武器未满级，添加武器升级选项
	var weapon_node = _get_weapon_node()
	if weapon_node and not weapon_node.is_max_level:
		pool.append({
			"name": weapon_node.get_level_display() + " → " + "Lv.%d" % (weapon_node.weapon_level + 2),
			"desc": "升级手枪：更多子弹/伤害/穿透",
			"apply": func(): weapon_node.level_up(),
		})

	# 从池中随机抽取 count 个不重复选项
	var result: Array[Dictionary] = []
	var available: Array[Dictionary] = pool.duplicate()

	for _i in count:
		if available.is_empty():
			# 池不够了，从头再来
			available = pool.duplicate()
		var idx: int = randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)

	return result


## 获取武器节点引用
func _get_weapon_node() -> Node:
	if not game_manager.player:
		return null
	return game_manager.player.get_node_or_null("WeaponPistol")
