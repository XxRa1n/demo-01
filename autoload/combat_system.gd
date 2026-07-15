extends Node

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

## 伤害管线（autoload）：所有对敌人 / 玩家的伤害统一入口。
##
## 决策顺序（固定，全系统契约）：
##   1. 易伤系数（冰 / fragile）
##   2. 暴击掷骰（非 DoT）
##   3. 斩杀判定
##   4. take_damage() 施加（签名不变，作为「仅施加」尾端）
##   5. 吸血回血
##   6. 元素状态附着（→ 可能触发反应）
##
## Phase 1：暴击 / 吸血 / 斩杀 / 元素附着均为 no-op（相关玩家字段尚未存在 / 默认值），
## 仅把伤害原样经 take_damage 施加——行为与重构前完全一致。
## 后续阶段在此函数内逐步打开各决策分支，不改 take_damage。

## 对敌人造成伤害的统一入口。
func damage_enemy(target: Node, info: DamageInfo) -> void:
	if not is_instance_valid(target) or not (target is CharacterBody2D):
		return
	# 死亡保护（take_damage 内也有，这里冗余检查更稳）
	if target.get("is_dead") == true:
		return

	var p = game_manager.player if (game_manager and is_instance_valid(game_manager.player)) else null

	# 1. 易伤系数（冰 / fragile，由 StatusHandler 提供）
	var sh = target.get("status")
	var vuln: float = sh.get_vulnerability_mult() if (sh != null and is_instance_valid(sh) and sh.has_method("get_vulnerability_mult")) else 1.0
	var amt: float = info.base_amount * vuln

	# 2. 暴击掷骰（非 DoT / 非反应产物 / 玩家存在 / 未预设暴击）
	if not info.is_dot and not info.is_reaction and p and not info.is_crit:
		if randf() < p.crit_rate:
			info.is_crit = true
	if info.is_crit and p:
		amt *= p.crit_damage_mult

	# 3. 斩杀判定（玩家开启斩杀、非 DoT、敌人当前血量低于 tier 阈值 → 强制致死）
	if not info.is_dot and p and p.execute_enabled and _should_execute(target):
		amt = float(target.get("enemy_hp"))

	info.final_amount = amt

	# 4. 施加（走原有 take_damage 尾端，签名不变）
	target.take_damage(amt, info.knockback_dir, info.knockback_force)

	# 5. 吸血（非 DoT、玩家有吸血）
	if not info.is_dot and p and p.lifesteal_pct > 0.0:
		p.heal(int(round(amt * p.lifesteal_pct)))

	# 6. 元素附着（非 DoT / 非反应产物 / 有元素 / 目标有 StatusHandler）
	if not info.is_dot and not info.is_reaction and info.element != DamageInfo.Element.NONE and sh != null and is_instance_valid(sh) and sh.has_method("apply"):
		sh.apply(info.element, _element_power(info), _element_duration(info), info)


## 元素附着强度：燃烧每跳 = 命中最终伤害的 20%（其余元素暂不用 power）。
func _element_power(info: DamageInfo) -> float:
	return info.final_amount * 0.2


## 元素持续时间：0 表示用各元素在 StatusHandler 内的默认时长。
func _element_duration(_info: DamageInfo) -> float:
	return 0.0


## 斩杀阈值：boss 5% / elite 10% / 普通 20%；无血量信息的对象不斩杀。
func _should_execute(target: Node) -> bool:
	var hp = target.get("enemy_hp")
	var max_hp = target.get("enemy_max_hp")
	if hp == null or max_hp == null or float(max_hp) <= 0.0:
		return false
	var threshold: float = 0.20
	match target.get("enemy_tier"):
		"boss":
			threshold = 0.05
		"elite":
			threshold = 0.10
	return float(hp) <= float(max_hp) * threshold


## 对玩家造成伤害的统一入口（敌人 → 玩家）。
func damage_player(amount: int, _source: Node = null) -> void:
	if not game_manager or not is_instance_valid(game_manager.player):
		return
	game_manager.player.take_damage(amount)
