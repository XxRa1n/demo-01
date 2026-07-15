extends Node

## 元素反应引擎（autoload）：维护元素两两反应的分发。
## 唯一触发点：StatusHandler.apply 在「新元素遇到异种已存元素」时调用 trigger()。
## 反应产物造伤用 is_reaction=true 的 DamageInfo（不再触发反应 / 不再附着元素），防递归。
## 反应产物附元素用 StatusHandler.apply_raw（裸附着，不触发反应）。

const DamageInfo = preload("res://scripts/combat/damage_info.gd")
const ReactionAoe = preload("res://effects/reaction_aoe.gd")
const ChainLightning = preload("res://effects/chain_lightning.gd")

## 反应参数（参考值，可调平衡）
const MELT_RADIUS := 110.0          # 火+冰 融化
const MELT_MULT := 3.0
const VAPOUR_RADIUS := 130.0        # 火+水 蒸汽
const VAPOUR_MULT := 1.5
const FREEZE_RADIUS := 130.0        # 水+冰 控场
const CHAIN_RADIUS := 170.0         # 水+雷 / 冰+雷 连锁
const CHAIN_JUMPS := 4
const CHAIN_DECAY := 0.8
const GRASS_BURN_RADIUS := 120.0    # 雷+草 范围燃烧

var _effects_container: Node2D = null


## 触发反应：a/b 为两个元素（顺序无关）。
func trigger(host: Node, a: int, b: int, src_info: Variant) -> void:
	if not is_instance_valid(host):
		return
	var src_dmg: float = src_info.final_amount if src_info != null else 0.0
	match _key(a, b):
		"fire|water":
			_vapour(host, src_dmg)
		"fire|ice":
			_melt(host, src_dmg)
		"fire|grass":
			pass  # 火+草 已在 StatusHandler 内就地强化燃烧，不生成实体
		"ice|water":
			_freeze(host)
		"lightning|water":
			_chain(host, src_dmg)
		"ice|lightning":
			_chain(host, src_dmg)
		"grass|lightning":
			_grass_burn(host)


## 火+冰 融化：大范围单次伤害。
func _melt(host: Node, src_dmg: float) -> void:
	_spawn_aoe(host.global_position, MELT_RADIUS, maxf(src_dmg * MELT_MULT, 15.0), DamageInfo.Element.NONE, Color(1.0, 0.5, 0.7, 0.6))


## 火+水 蒸汽：大范围一次性伤害 + 点燃范围内敌人（持续 debuff 的近似）。
func _vapour(host: Node, src_dmg: float) -> void:
	_spawn_aoe(host.global_position, VAPOUR_RADIUS, maxf(src_dmg * VAPOUR_MULT, 8.0), DamageInfo.Element.FIRE, Color(0.9, 0.85, 1.0, 0.5))


## 水+冰 控场：给范围内敌人附水（减速）。
func _freeze(host: Node) -> void:
	_spawn_aoe(host.global_position, FREEZE_RADIUS, 0.0, DamageInfo.Element.WATER, Color(0.6, 0.8, 1.0, 0.5))


## 水+雷 / 冰+雷 连锁闪电。
func _chain(host: Node, src_dmg: float) -> void:
	var cl := ChainLightning.new()
	cl.setup(maxf(src_dmg, 10.0), CHAIN_JUMPS, CHAIN_RADIUS, CHAIN_DECAY)
	cl.global_position = host.global_position
	_add_effect(cl)


## 雷+草 范围燃烧：给范围内敌人附火。
func _grass_burn(host: Node) -> void:
	_spawn_aoe(host.global_position, GRASS_BURN_RADIUS, 0.0, DamageInfo.Element.FIRE, Color(0.5, 1.0, 0.4, 0.5))


func _spawn_aoe(pos: Vector2, radius: float, dmg: float, element: int, color: Color) -> void:
	var aoe := ReactionAoe.new()
	aoe.setup(radius, dmg, element, color)
	aoe.global_position = pos
	_add_effect(aoe)


func _add_effect(node: Node2D) -> void:
	var c := _get_effects_container()
	if c:
		c.add_child(node)
	else:
		add_child(node)  # fallback：无 GameWorld 时挂自身，避免崩溃


## 惰性获取 / 创建 Effects 容器（与 Projectiles 同级，避免改场景文件）。
func _get_effects_container() -> Node2D:
	if is_instance_valid(_effects_container):
		return _effects_container
	var gw := get_node_or_null("/root/Main/GameWorld")
	if gw:
		var e := gw.get_node_or_null("Effects")
		if e == null:
			e = Node2D.new()
			e.name = "Effects"
			gw.add_child(e)
		_effects_container = e
	return _effects_container


func _key(a: int, b: int) -> String:
	return _name(mini(a, b)) + "|" + _name(maxi(a, b))


func _name(e: int) -> String:
	match e:
		DamageInfo.Element.FIRE:
			return "fire"
		DamageInfo.Element.WATER:
			return "water"
		DamageInfo.Element.ICE:
			return "ice"
		DamageInfo.Element.LIGHTNING:
			return "lightning"
		DamageInfo.Element.GRASS:
			return "grass"
		_:
			return "none"
