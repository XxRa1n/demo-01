extends Node

## 敌人状态组件（挂为敌人的子节点，由 enemy_base._ready 自动创建）。
## 持有五种元素状态（火燃烧 / 水减速 / 冰易伤 / 雷 / 草），自带 _process tick，
## 对外提供 get_slow_mult() / get_vulnerability_mult() 供移动与伤害管线读取。
##
## 反应入口（apply）：新元素遇到异种已存元素 → 消费两者、交 reaction_engine 触发反应。
##   特例：火+草 只消费草、强化并加速燃烧（保留火），不生成实体。
## 反应实体用 apply_raw() 裸附着，跳过反应检查，防链式反应失控。

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 各元素默认时长 / tick（秒）
const BURN_DURATION := 4.0
const BURN_TICK := 0.5
const CHILL_DURATION := 3.0       # 水：减速
const FRAGILE_DURATION := 4.0     # 冰：易伤
const FRAGILE_BONUS := 0.20       # 冰：+20% 承伤
const SLOW_FACTOR := 0.5          # 水：移速 ×0.5
const SHOCK_DURATION := 1.0       # 雷：连锁反应时由 reaction_engine 即时处理，此处仅占位
const GRASS_DURATION := 6.0       # 草：Phase 6 死亡掉落 / 荆棘用，此处仅占位

## 活动状态：Element(int) -> { power, time_left, tick_acc(仅燃烧), accel(仅燃烧) }
var _statuses: Dictionary = {}

## 派生系数（combat / movement 读取）
var _slow_mult: float = 1.0
var _vuln_mult: float = 1.0


func _process(delta: float) -> void:
	if _statuses.is_empty():
		return
	var host := get_parent()
	if not is_instance_valid(host):
		return

	var expired: Array = []
	for el in _statuses:
		var s: Dictionary = _statuses[el]
		s["time_left"] = float(s["time_left"]) - delta
		# 燃烧 DoT：每 tick_interval 秒跳一次（accel 加速）
		if int(el) == DamageInfo.Element.FIRE:
			s["tick_acc"] = float(s["tick_acc"]) + delta
			var tick_interval: float = BURN_TICK / float(s.get("accel", 1.0))
			if float(s["tick_acc"]) >= tick_interval:
				s["tick_acc"] = 0.0
				_burn_tick(host, float(s.get("power", 0.0)))
		if float(s["time_left"]) <= 0.0:
			expired.append(el)
	for el in expired:
		_statuses.erase(el)
	_recompute_multipliers()


## 燃烧一跳：is_dot=true → 跳过暴击 / 吸血 / 斩杀 / 元素附着（不重新点燃，防自激）。
func _burn_tick(host: Node, power: float) -> void:
	if power <= 0.0:
		return
	var info := DamageInfo.new(power, DamageInfo.Element.NONE, Vector2.ZERO, 0.0)
	info.is_dot = true
	combat_system.damage_enemy(host, info)


## 附着元素状态（含反应检查）。
## 若敌人已带异种元素 → 触发反应（火+草特例：只消费草、强化燃烧）。
## duration<=0 表示用该元素默认时长。
func apply(element: int, power: float = 1.0, duration: float = 0.0, src_info: Variant = null) -> void:
	var existing := _other_element(element)
	if existing != DamageInfo.Element.NONE:
		# 火+草：消费草、强化并加速燃烧（保留火）
		if (existing == DamageInfo.Element.FIRE and element == DamageInfo.Element.GRASS) \
				or (existing == DamageInfo.Element.GRASS and element == DamageInfo.Element.FIRE):
			consume(DamageInfo.Element.GRASS)
			_boost_burn(2.0, 2.0)
			return
		# 其余反应：消费两者、交反应引擎
		consume(existing)
		consume(element)
		reaction_engine.trigger(get_parent(), existing, element, src_info)
		return
	_apply_status(element, power, duration)


## 反应实体用的「裸附着」：直接加状态，不做反应检查（防链式反应失控）。
func apply_raw(element: int, power: float = 1.0, duration: float = 0.0) -> void:
	_apply_status(element, power, duration)


func _apply_status(element: int, power: float, duration: float) -> void:
	match element:
		DamageInfo.Element.FIRE:
			# 燃烧：刷新时长，power 取较强（已存则 max），accel 继承
			var prev_power: float = 0.0
			var prev_accel: float = 1.0
			if _statuses.has(DamageInfo.Element.FIRE):
				prev_power = float(_statuses[DamageInfo.Element.FIRE].get("power", 0.0))
				prev_accel = float(_statuses[DamageInfo.Element.FIRE].get("accel", 1.0))
			_statuses[DamageInfo.Element.FIRE] = {
				"power": maxf(power, prev_power),
				"time_left": BURN_DURATION if duration <= 0.0 else duration,
				"tick_acc": BURN_TICK,  # 首次立即跳一次
				"accel": prev_accel,
			}
		DamageInfo.Element.WATER:
			_statuses[DamageInfo.Element.WATER] = {"time_left": CHILL_DURATION if duration <= 0.0 else duration}
		DamageInfo.Element.ICE:
			_statuses[DamageInfo.Element.ICE] = {"time_left": FRAGILE_DURATION if duration <= 0.0 else duration}
		DamageInfo.Element.LIGHTNING:
			_statuses[DamageInfo.Element.LIGHTNING] = {"time_left": SHOCK_DURATION if duration <= 0.0 else duration}
		DamageInfo.Element.GRASS:
			_statuses[DamageInfo.Element.GRASS] = {"time_left": GRASS_DURATION if duration <= 0.0 else duration}
	_recompute_multipliers()


func get_slow_mult() -> float:
	return _slow_mult


func get_vulnerability_mult() -> float:
	return _vuln_mult


func has(element: int) -> bool:
	return _statuses.has(element)


## 清空某元素（反应消费用）。
func consume(element: int) -> void:
	_statuses.erase(element)
	_recompute_multipliers()


## 返回当前已存、且不同于 element 的第一个元素；无则 NONE。
func _other_element(element: int) -> int:
	for el in _statuses:
		if int(el) != element:
			return int(el)
	return DamageInfo.Element.NONE


## 强化燃烧（火+草反应）：power ×mult、tick 间隔 ÷accel。
func _boost_burn(mult: float, accel: float) -> void:
	if not _statuses.has(DamageInfo.Element.FIRE):
		return
	var s: Dictionary = _statuses[DamageInfo.Element.FIRE]
	s["power"] = float(s.get("power", 0.0)) * mult
	s["accel"] = float(s.get("accel", 1.0)) * accel


func _recompute_multipliers() -> void:
	_slow_mult = 1.0
	_vuln_mult = 1.0
	if _statuses.has(DamageInfo.Element.WATER):
		_slow_mult = SLOW_FACTOR
	if _statuses.has(DamageInfo.Element.ICE):
		_vuln_mult = 1.0 + FRAGILE_BONUS
