extends "res://scripts/projectile/projectile_base.gd"

## 衰减弹丸（霰弹枪用）：飞行距离越远伤害越低，超过 max_range 销毁。
## 继承 projectile_base 的直线飞行 / 命中 / 穿透 / 越界销毁逻辑，只追加按距离的衰减。

## 衰减区间（像素）：<=falloff_start 全伤，>=falloff_end 降到 min_damage_ratio
var falloff_start: float = 250.0
var falloff_end: float = 500.0
var max_range: float = 520.0       # 超出即销毁
var min_damage_ratio: float = 0.5  # 远端最低伤害比例
var base_damage_full: float = 0.0  # 发射时的全额伤害（衰减基准）
var _distance: float = 0.0         # 累计飞行距离


func _physics_process(delta: float) -> void:
	# 父类：直线飞行 + 越界销毁（内部有 is_destroyed 守卫）
	super._physics_process(delta)
	if is_destroyed:
		return
	# 累计飞行距离并重算当前伤害
	_distance += projectile_speed * delta
	var ratio: float
	if _distance <= falloff_start:
		ratio = 1.0
	elif _distance >= falloff_end:
		ratio = min_damage_ratio
	else:
		var t := (_distance - falloff_start) / (falloff_end - falloff_start)
		ratio = lerpf(1.0, min_damage_ratio, t)
	projectile_damage = base_damage_full * ratio
	# 超出最大射程销毁
	if _distance >= max_range:
		queue_free()


## 由武器在 setup() 之后调用：记录全额伤害与衰减参数
func set_falloff(full_dmg: float, p_start: float, p_end: float, p_max_range: float) -> void:
	base_damage_full = full_dmg
	projectile_damage = full_dmg  # 初始全伤
	falloff_start = p_start
	falloff_end = p_end
	max_range = p_max_range
