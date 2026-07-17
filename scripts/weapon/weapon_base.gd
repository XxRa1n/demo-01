class_name WeaponBase
extends Node

const DamageInfo = preload("res://scripts/combat/damage_info.gd")
const Beam = preload("res://effects/beam.gd")

## 武器基类：通用逻辑——冷却计时、固定升级模板、随机词条、找敌、伤害计算、宝石槽、容器获取。
## 升级路径（宝石.md，所有武器统一）：
##   L2 增加伤害 / L3 增加随机词条 / L4 增加攻速 / L5 专属机制(子类覆盖 _apply_special) /
##   L6 增加随机词条 / L7 减少技能cd / L8 +2宝石槽 & 随机词条
## 子类只需：_init() 写基础数值 + _count_supported/_pierce_supported；_fire() 用基础常量；
##          _apply_special() 写 L5 专属。弹数/穿透/范围 等成长由词条累积，无需自写等级表。

## 武器元信息（子类在 _init() 赋值）
var weapon_id: StringName = &""
var display_name: String = ""
var weapon_icon_color: Color = Color(1.0, 1.0, 1.0)
var base_damage: float = 10.0
var base_cooldown: float = 1.0

## 等级（0 = Lv.1）
var weapon_level: int = 0
var is_max_level: bool = false

## 内部计时
var cooldown_timer: float = 0.0

## 子弹容器（惰性获取，重启后重取）
var projectiles_container: Node2D = null

## 环绕实体 / 召唤物缓存
var _orbit_blades: Array = []
var _minions: Array = []

## 宝石槽
var gem_slots: Array = []
var max_gem_slots: int = 1
var _params: Dictionary = {}

# ─── 升级累积状态（固定模板 + 随机词条驱动）──────────────────────
var _dmg_mult: float = 1.0       # L2 增加伤害 / 伤害词条
var _cd_mult: float = 1.0        # L4 增加攻速 / L7 减cd / 攻速词条
var _size_mult: float = 1.0      # 范围词条（射程 / 半径 / 速度）
var _kb_mult: float = 1.0        # 击退词条
var _count_bonus: int = 0        # 数量词条（弹数 / 召唤物 / 飞斧）
var _pierce_bonus: int = 0       # 穿透词条
var _affixes: Array = []         # 已获得词条名（展示用）
## L5 专属是否激活（子类在 _fire 里据此分支到专属行为）
var _l5_active: bool = false
## 临时附魔（宝石法术 L5）：持续期间武器命中元素 = _enchant_element
var _enchant_element: int = 0
var _enchant_timer: float = 0.0
## 临时增益（巨剑变大5s / 旋转飞斧3s / 猫分身10s）：持续期间临时加 伤害/范围/数量，到期自动还原
var _buff_active: bool = false
var _buff_timer: float = 0.0
var _buff_dmg: float = 1.0       # 应用时的伤害倍率（还原用）
var _buff_size: float = 1.0      # 应用时的范围倍率
var _buff_count: int = 0         # 应用时临时加的数量
var _buff_cd: float = 0.0        # 增益冷却（周期性增益的间隔，如猫分身/飞斧爆发）
## 该武器是否吃「数量 / 穿透」词条（子类在 _init 设置）
var _count_supported: bool = false
var _pierce_supported: bool = false

## 固定模板数值
const L2_DAMAGE_MULT: float = 1.25   # 增加伤害
const L4_CD_MULT: float = 0.85       # 增加攻速
const L7_CD_MULT: float = 0.8        # 减少技能cd
const AFFIX_DAMAGE_MULT: float = 1.12
const AFFIX_CD_MULT: float = 0.9
const AFFIX_SIZE_MULT: float = 1.15
const AFFIX_KB_MULT: float = 1.3
const ENCHANT_DURATION: float = 10.0   # 宝石法术附魔时长


func _ready() -> void:
	# 等一帧让 main 场景就绪，再取容器
	await get_tree().process_frame
	_refresh_container()


func _process(delta: float) -> void:
	if game_manager.game_over or game_manager.is_paused:
		return
	if not game_manager.player:
		return
	# 临时增益计时（附魔 / 临时增益 buff）
	if _enchant_timer > 0.0:
		_enchant_timer -= delta
	if _buff_active:
		_buff_timer -= delta
		if _buff_timer <= 0.0:
			_buff_active = false
			_dmg_mult /= _buff_dmg
			_size_mult /= _buff_size
			_count_bonus -= _buff_count
			_buff_dmg = 1.0
			_buff_size = 1.0
			_buff_count = 0
	if _buff_cd > 0.0:
		_buff_cd -= delta
	if not is_instance_valid(projectiles_container):
		_refresh_container()
	if not is_instance_valid(projectiles_container):
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		_params = _compute_fire_params()
		var cd := base_cooldown * _cd_mult
		if float(_params.get("cooldown_override", 0.0)) > 0.0:  # 技能cd 宝石
			cd = float(_params["cooldown_override"])
		cooldown_timer = cd * game_manager.player.cooldown_mult
		_fire()


func _refresh_container() -> void:
	projectiles_container = get_node_or_null("/root/Main/GameWorld/Projectiles")


## 抽象：子类覆盖发射逻辑
func _fire() -> void:
	pass


## 公共工具：找最近敌人
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


## 公共工具：随机一个敌人的位置（无敌人返回 null）。火枪空袭等随机砸敌用。
func _random_enemy_pos() -> Variant:
	if not enemy_spawner.enemies_container:
		return null
	var arr: Array = []
	for child in enemy_spawner.enemies_container.get_children():
		if child is CharacterBody2D and is_instance_valid(child):
			arr.append(child)
	if arr.is_empty():
		return null
	return arr[randi() % arr.size()].global_position


## 伤害 = base_damage × mult × _dmg_mult(升级/词条) × player.might
func _calc_damage(mult: float = 1.0) -> float:
	return base_damage * mult * _dmg_mult * game_manager.player.might


# ─── 固定升级模板 ─────────────────────────────────────────────
## 升级：按「升级后达到的等级」套用固定模板（所有武器一致，仅 L5 调子类 _apply_special）。
func level_up() -> bool:
	if is_max_level:
		return false
	weapon_level += 1
	match weapon_level + 1:  # 升级后达到的等级 (2..8)
		2:  # 增加伤害
			_dmg_mult *= L2_DAMAGE_MULT
		3:  # 增加随机词条
			_roll_affix()
		4:  # 增加攻速
			_cd_mult *= L4_CD_MULT
		5:  # 专属机制
			_l5_active = true
			_apply_special()
		6:  # 增加随机词条
			_roll_affix()
		7:  # 减少技能cd
			_cd_mult *= L7_CD_MULT
		8:  # +2 宝石槽 & 随机词条
			max_gem_slots += 2
			_roll_affix()
	if weapon_level >= 7:  # Lv.8
		is_max_level = true
	return true


## 子类覆盖：L5 专属机制（默认空）。
func _apply_special() -> void:
	pass


## 随机词条池：通用 4 种 + 武器支持的「数量 / 穿透」。
func _affix_pool() -> Array:
	var pool: Array = ["dmg", "cd", "size", "kb"]
	if _count_supported:
		pool.append("count")
	if _pierce_supported:
		pool.append("pierce")
	return pool


## 随机抽取并应用一个词条。
func _roll_affix() -> void:
	var pool := _affix_pool()
	var pick: String = pool[randi() % pool.size()]
	match pick:
		"dmg":
			_dmg_mult *= AFFIX_DAMAGE_MULT
			_affixes.append("伤害+")
		"cd":
			_cd_mult *= AFFIX_CD_MULT
			_affixes.append("攻速+")
		"size":
			_size_mult *= AFFIX_SIZE_MULT
			_affixes.append("范围+")
		"kb":
			_kb_mult *= AFFIX_KB_MULT
			_affixes.append("击退+")
		"count":
			_count_bonus += 1
			_affixes.append("数量+")
		"pierce":
			_pierce_bonus += 1
			_affixes.append("穿透+")


func get_level_display() -> String:
	return "%s Lv.%d" % [display_name, weapon_level + 1]


func get_next_level_display() -> String:
	return "%s Lv.%d→%d" % [display_name, weapon_level + 1, weapon_level + 2]


## 升级卡片描述：下一级固定升级类型；满级则展示已得词条。
func get_upgrade_description() -> String:
	if is_max_level:
		return "已满级｜词条: " + (", ".join(_affixes) if not _affixes.is_empty() else "无")
	var next := weapon_level + 2
	var desc := _upgrade_name(next)
	if not _affixes.is_empty():
		desc += "｜已得: " + ", ".join(_affixes)
	return desc


func _upgrade_name(lv: int) -> String:
	match lv:
		2:
			return "增加伤害"
		3:
			return "增加随机词条"
		4:
			return "增加攻速"
		5:
			return "专属机制"
		6:
			return "增加随机词条"
		7:
			return "减少技能cd"
		8:
			return "+2宝石槽 & 随机词条"
		_:
			return "升级"


# ─── 开火助手（自动叠加词条 / 宝石派生参数）────────────────────
## 朝最近敌人发射扇形扩散直线子弹（ProjectileBase 共用）。
func _fire_seek_spread(scene: PackedScene, count: int, spread: float, speed: float, dmg: float, pierce: int, element: int = DamageInfo.Element.NONE) -> void:
	var nearest := _find_nearest_enemy()
	if nearest == null:
		return
	var el: int = _gem_element(element)
	var volleys: int = _gem_attack_count()
	count += _count_bonus
	pierce += _pierce_bonus
	speed *= _size_mult
	var base_dir := (nearest.global_position - game_manager.player.global_position).normalized()
	var start: float = -spread * float(count - 1) / 2.0
	for _v in volleys:
		for i in count:
			var dir := base_dir.rotated(start + spread * float(i)) if count > 1 else base_dir
			var proj := scene.instantiate()
			proj.setup(dmg, speed, dir, pierce, el, self)
			proj.global_position = game_manager.player.global_position
			projectiles_container.add_child(proj)


## 朝最近敌人发射爆炸弹（LocatedBase 共用）。数量词条/连击宝石多发齐投；范围/击退词条放大。
func _fire_lob(scene: PackedScene, speed: float, dmg: float, blast: float, knockback: float) -> void:
	var nearest := _find_nearest_enemy()
	if nearest == null:
		return
	var el: int = _gem_element()
	var shots: int = (1 + _count_bonus) * _gem_attack_count()
	var dir := (nearest.global_position - game_manager.player.global_position).normalized()
	blast *= _size_mult
	knockback *= _kb_mult
	for _i in shots:
		var proj := scene.instantiate()
		proj.setup(dmg, speed, dir, blast, knockback, el, self)
		proj.global_position = game_manager.player.global_position
		projectiles_container.add_child(proj)


## 向多个固定方向同时发射持续光束（laser X型 / 环绕圣经米字 用）。
func _fire_beams(directions: Array, dps: float, length: float, width: float, active: float, element: int = DamageInfo.Element.NONE) -> void:
	for d in directions:
		var b := Beam.new()
		b.setup(dps, length, width, active, element, self)
		b.set_fixed_dir(d)
		b.global_position = game_manager.player.global_position
		projectiles_container.add_child(b)


## 维持 N 个环绕实体（OrbitEntity 共用）。数量词条 +刀，范围词条 +半径；元素取自宝石。
func _sync_orbit_blades(blade_scene: PackedScene, count: int, radius: float, speed: float, dmg: float, element: int = DamageInfo.Element.NONE) -> void:
	if not is_instance_valid(projectiles_container):
		return
	count += _count_bonus
	radius *= _size_mult
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


## 维持 N 个召唤物（Minion 共用）。数量词条 +召唤物。
func _sync_minions(factory: Callable, count: int, setup_fn: Callable) -> void:
	if not is_instance_valid(projectiles_container):
		return
	count += _count_bonus
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
	# 临时附魔（宝石法术 L5）覆盖元素
	if _enchant_timer > 0.0:
		p["element"] = _enchant_element
	return p


## 随机附魔一个元素，持续 ENCHANT_DURATION 秒（宝石法术 L5 用）。
func _roll_enchant() -> void:
	var els: Array = [DamageInfo.Element.FIRE, DamageInfo.Element.WATER, DamageInfo.Element.ICE, DamageInfo.Element.LIGHTNING, DamageInfo.Element.GRASS]
	_enchant_element = int(els[randi() % els.size()])
	_enchant_timer = ENCHANT_DURATION


## 临时增益（巨剑变大 / 旋转飞斧 / 猫分身 用）：临时加 伤害/范围/数量，duration 秒后自动还原。
## 已在增益中则只刷新时长（不叠层）。
func _start_buff(dmg: float, size: float, count: int, duration: float) -> void:
	if _buff_active:
		_buff_timer = duration
		return
	_buff_active = true
	_buff_dmg = dmg
	_buff_size = size
	_buff_count = count
	_dmg_mult *= dmg
	_size_mult *= size
	_count_bonus += count
	_buff_timer = duration


func _gem_element(fallback: int = DamageInfo.Element.NONE) -> int:
	if _params.is_empty():
		return fallback
	return int(_params.get("element", fallback))


func _gem_attack_count() -> int:
	if _params.is_empty():
		return 1
	return int(_params.get("attack_count", 1))


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
