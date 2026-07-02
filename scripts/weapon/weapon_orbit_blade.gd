extends WeaponBase

## 回旋刀武器：不发射子弹，而是维护一组常驻刀刃实体绕玩家旋转。
## _fire 幂等同步刀刃数量与参数到当前等级；level_up 后立即同步。
## 刀刃实体放 Projectiles 容器（随场景重载销毁，重启零残留）。

## 等级数据：blades 刀数、damage_mult 伤害、radius 旋转半径、speed 角速度
const LEVEL_DATA: Array = [
	{"blades": 1, "damage_mult": 1.0, "radius": 90.0, "speed": 3.5},   # Lv.1
	{"blades": 1, "damage_mult": 1.1, "radius": 95.0, "speed": 3.6},   # Lv.2
	{"blades": 2, "damage_mult": 1.1, "radius": 100.0, "speed": 3.7},  # Lv.3
	{"blades": 2, "damage_mult": 1.2, "radius": 105.0, "speed": 3.8},  # Lv.4
	{"blades": 3, "damage_mult": 1.2, "radius": 110.0, "speed": 3.9},  # Lv.5
	{"blades": 3, "damage_mult": 1.3, "radius": 115.0, "speed": 4.0},  # Lv.6
	{"blades": 4, "damage_mult": 1.3, "radius": 120.0, "speed": 4.1},  # Lv.7
	{"blades": 4, "damage_mult": 1.4, "radius": 130.0, "speed": 4.2},  # Lv.8
]

const blade_scene: PackedScene = preload("res://effects/orbit_blade.tscn")
const PER_HIT_BASE: float = 4.0  # 单次命中基础伤害

var _blades: Array = []  # 当前刀刃实体列表


func _init() -> void:
	weapon_id = &"orbit_blade"
	display_name = "回旋刀"
	weapon_icon_color = Color(0.9, 0.9, 0.9)
	base_damage = PER_HIT_BASE
	base_cooldown = 0.3  # 仅驱动 _fire 周期性同步检查（不真的发射）


func _level_data() -> Array:
	return LEVEL_DATA


func get_upgrade_description() -> String:
	return "更多刀刃 / 伤害 / 更大半径"


func _fire() -> void:
	# 幂等同步：刀刃数量与参数对齐当前等级
	_sync_blades()


## 按当前等级同步刀刃数量与参数（增减实体 + 更新均布相位）
func _sync_blades() -> void:
	if not is_instance_valid(projectiles_container):
		_refresh_container()
	if not is_instance_valid(projectiles_container):
		return

	var data: Dictionary = get_current_level_data()
	var want: int = int(data.get("blades", 1))
	var radius: float = float(data.get("radius", 90.0))
	var speed: float = float(data.get("speed", 3.5))
	var dmg: float = _calc_damage(float(data.get("damage_mult", 1.0)))

	# 清理已失效的引用
	_blades = _blades.filter(func(b): return is_instance_valid(b))

	# 增减刀数
	while _blades.size() < want:
		var blade := blade_scene.instantiate()
		projectiles_container.add_child(blade)
		_blades.append(blade)
	while _blades.size() > want:
		var extra = _blades.pop_back()
		if is_instance_valid(extra):
			extra.queue_free()

	# 更新参数 + 多刀均布相位
	for i in _blades.size():
		var base_angle := (float(i) / float(max(_blades.size(), 1))) * TAU
		_blades[i].set_params(radius, speed, base_angle, dmg)


## 升级后立即同步刀刃，不必等下次 _fire
func level_up() -> bool:
	var ok := super.level_up()
	if ok:
		_sync_blades()
	return ok
