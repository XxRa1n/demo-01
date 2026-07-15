extends RefCounted
## 注意：不使用 class_name（本环境 class_name 全局缓存不稳定，autoload 解析时找不到类型）。
## 各消费方用 `const DamageInfo = preload("res://scripts/combat/damage_info.gd")` 引用，
## 这样 DamageInfo.new() / DamageInfo.Element.X / 类型注解 info: DamageInfo 均可解析。

## 伤害信息载体：所有伤害经 combat_system.damage_enemy 时携带。
## 元素枚举是全系统（状态 / 反应 / 宝石）共享的唯一元素定义。
##
## 这是纯数据对象（RefCounted，无需 queue_free），不依赖任何 autoload，
## 由武器/飞行体在命中时构造，交给 combat_system 决策后施加。

## 元素：NONE=纯物理，其余五种对应属性宝石与反应。
enum Element { NONE, FIRE, WATER, ICE, LIGHTNING, GRASS }

## 基础伤害量（管线决策前的原始值，由武器 _calc_damage 给出）
var base_amount: float = 0.0
## 命中附带的元素（Element 枚举）
var element: int = Element.NONE
## 击退方向（归一化）与力度
var knockback_dir: Vector2 = Vector2.ZERO
var knockback_force: float = 0.0
## 是否暴击（由管线掷骰设置；外部预设 true 可强制暴击）
var is_crit: bool = false
## 是否持续伤害（燃烧 / 荆棘 tick）——跳过暴击 / 吸血 / 斩杀 / 元素附着，避免自激
var is_dot: bool = false
## 是否元素反应产生的伤害——反应产物造伤但不再触发反应，防递归
var is_reaction: bool = false
## 伤害来源武器（反应原点 / 击杀归属；可能为空）
var source_weapon: Node = null
## 管线决策后的最终伤害量（暴击 / 易伤后），供日志 / UI 取用
var final_amount: float = 0.0


func _init(p_amount: float = 0.0, p_element: int = Element.NONE, p_dir: Vector2 = Vector2.ZERO, p_force: float = 0.0) -> void:
	base_amount = p_amount
	element = p_element
	knockback_dir = p_dir
	knockback_force = p_force
