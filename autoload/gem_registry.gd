extends Node

## 宝石注册表（autoload）：18 种宝石定义（13 功能 + 5 元素）。
## 分类：
##   GLOBAL      —— 镶嵌到任一武器即全局生效（改玩家属性），apply_global/revert_global 成对可逆（乘除叠加）。
##   GLOBAL_FLAG —— 置玩家布尔开关（嗜血/斩杀/杀敌成长），由 kill_tracker 读取。
##   FIRE_MOD    —— 仅对该武器生效（连击/2020/技能cd/击退），由 WeaponBase._compute_fire_params 读取。
##   ELEMENT     —— 设该武器命中元素，由 WeaponBase._compute_fire_params 读取。
## 元素 / 连击 等不必 apply/revert，每次开火动态计算；只有 GLOBAL 与 GLOBAL_FLAG 需要在镶嵌时立即生效。

const DamageInfo = preload("res://scripts/combat/damage_info.gd")

enum Cat { FIRE_MOD, GLOBAL, GLOBAL_FLAG, ELEMENT }

const GEMS: Dictionary = {
	&"double_strike": {"display": "连击", "desc": "每次攻击多发射一发", "cat": Cat.FIRE_MOD},
	&"bloodlust": {"display": "嗜血", "desc": "每 20 击杀激活 10s：+20%攻击/+10%攻速/+10%移速", "cat": Cat.GLOBAL_FLAG},
	&"lifesteal": {"display": "吸血", "desc": "吸血 +1%", "cat": Cat.GLOBAL},
	&"knockback": {"display": "击退", "desc": "该武器击退效果增强", "cat": Cat.FIRE_MOD},
	&"execute": {"display": "斩杀", "desc": "开启斩杀（低血敌人直接秒杀）", "cat": Cat.GLOBAL_FLAG},
	&"crit": {"display": "暴击", "desc": "暴击率 +20%", "cat": Cat.GLOBAL},
	&"crit_damage": {"display": "暴伤", "desc": "暴击伤害 +40%", "cat": Cat.GLOBAL},
	&"skill_cd": {"display": "技能CD", "desc": "该武器冷却 -1s", "cat": Cat.FIRE_MOD},
	&"kill_atk": {"display": "杀敌+攻击", "desc": "每 100 击杀永久 +5%攻击", "cat": Cat.GLOBAL_FLAG},
	&"kill_atkspd": {"display": "杀敌+攻速", "desc": "每 100 击杀永久 +5%攻速", "cat": Cat.GLOBAL_FLAG},
	&"soy_milk": {"display": "豆浆", "desc": "攻速 +200%、攻击 -35%", "cat": Cat.GLOBAL},
	&"giant_eye": {"display": "巨眼", "desc": "攻击 +400%、攻速 -60%", "cat": Cat.GLOBAL},
	&"2020": {"display": "2020", "desc": "每次多发射一发（平行）", "cat": Cat.FIRE_MOD},
	&"fire": {"display": "火宝石", "desc": "武器命中附燃烧", "cat": Cat.ELEMENT, "element": DamageInfo.Element.FIRE},
	&"water": {"display": "水宝石", "desc": "武器命中附减速", "cat": Cat.ELEMENT, "element": DamageInfo.Element.WATER},
	&"ice": {"display": "冰宝石", "desc": "武器命中附易伤", "cat": Cat.ELEMENT, "element": DamageInfo.Element.ICE},
	&"lightning": {"display": "雷宝石", "desc": "武器命中附雷", "cat": Cat.ELEMENT, "element": DamageInfo.Element.LIGHTNING},
	&"grass": {"display": "草宝石", "desc": "武器命中附草", "cat": Cat.ELEMENT, "element": DamageInfo.Element.GRASS},
}


func get_def(gem_id: Variant) -> Dictionary:
	return GEMS.get(gem_id, {})


func is_global_apply(gem_id: Variant) -> bool:
	var d: Dictionary = GEMS.get(gem_id, {})
	return not d.is_empty() and d.get("cat") == Cat.GLOBAL


func is_flag(gem_id: Variant) -> bool:
	var d: Dictionary = GEMS.get(gem_id, {})
	return not d.is_empty() and d.get("cat") == Cat.GLOBAL_FLAG


## 全局宝石：镶嵌时改玩家属性（乘除叠加，与被动/嗜血/杀敌成长独立可逆）。
func apply_global(gem_id: Variant, p: Node) -> void:
	match gem_id:
		&"lifesteal":
			p.lifesteal_pct += 0.01
		&"crit":
			p.crit_rate = minf(p.crit_rate + 0.20, 1.0)
		&"crit_damage":
			p.crit_damage_mult += 0.40
		&"soy_milk":
			p.might *= 0.65
			p.cooldown_mult *= (1.0 / 3.0)  # 攻速 +200% → 冷却 ×1/3
		&"giant_eye":
			p.might *= 5.0
			p.cooldown_mult *= 2.5  # 攻速 -60% → 冷却 ×2.5


func revert_global(gem_id: Variant, p: Node) -> void:
	match gem_id:
		&"lifesteal":
			p.lifesteal_pct = maxf(p.lifesteal_pct - 0.01, 0.0)
		&"crit":
			p.crit_rate = maxf(p.crit_rate - 0.20, 0.0)
		&"crit_damage":
			p.crit_damage_mult -= 0.40
		&"soy_milk":
			p.might /= 0.65
			p.cooldown_mult /= (1.0 / 3.0)
		&"giant_eye":
			p.might /= 5.0
			p.cooldown_mult /= 2.5


## 开关类宝石：置玩家布尔（kill_tracker 据此驱动嗜血/杀敌成长）。
func apply_flag(gem_id: Variant, p: Node) -> void:
	match gem_id:
		&"bloodlust":
			p.bloodlust_enabled = true
		&"execute":
			p.execute_enabled = true
		&"kill_atk":
			p.kill_atk_enabled = true
		&"kill_atkspd":
			p.kill_atkspd_enabled = true


func revert_flag(gem_id: Variant, p: Node) -> void:
	match gem_id:
		&"bloodlust":
			p.bloodlust_enabled = false
		&"execute":
			p.execute_enabled = false
		&"kill_atk":
			p.kill_atk_enabled = false  # 已获得的永久加成不回收，仅停止后续累计
		&"kill_atkspd":
			p.kill_atkspd_enabled = false


func all_ids() -> Array:
	return GEMS.keys()
