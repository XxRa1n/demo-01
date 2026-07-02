extends Area2D

## 爆炸弹（火箭炮用）：慢速飞行，命中敌人或飞到最大射程时爆炸，
## 对爆炸半径内所有敌人造成伤害 + 击退。
## 不复用 projectile_base：它的命中是「直接 take_damage + 销毁」；这里要 AoE 范围伤害。
## 碰撞层 layer=4/mask=2（命中敌人触发爆炸）。

var explosion_damage: float = 30.0
var blast_radius: float = 90.0
var knockback_force: float = 400.0
var projectile_speed: float = 320.0
var direction: Vector2 = Vector2.RIGHT

const MAX_RANGE: float = 600.0    # 飞到此时引爆
const DESPAWN_MARGIN: float = 100.0

var is_destroyed: bool = false
var _distance: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 大号占位纹理（橙红色）
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.95, 0.45, 0.2))
	sprite.texture = ImageTexture.create_from_image(img)
	if direction.length_squared() > 0.01:
		rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	position += direction * projectile_speed * delta
	_distance += projectile_speed * delta
	# 到达最大射程 → 引爆
	if _distance >= MAX_RANGE:
		_explode()
		return
	# 飞出地图 → 直接销毁（不爆炸）
	var map_size := game_manager.MAP_SIZE
	if global_position.x < -DESPAWN_MARGIN or global_position.x > map_size.x + DESPAWN_MARGIN \
			or global_position.y < -DESPAWN_MARGIN or global_position.y > map_size.y + DESPAWN_MARGIN:
		queue_free()


func setup(dmg: float, spd: float, dir: Vector2, blast: float, knockback: float) -> void:
	explosion_damage = dmg
	projectile_speed = spd
	direction = dir.normalized()
	blast_radius = blast
	knockback_force = knockback


func _on_body_entered(body: Node2D) -> void:
	if is_destroyed:
		return
	# 命中任一敌人 → 引爆
	if body is CharacterBody2D and body.has_method("take_damage"):
		_explode()


## 爆炸：遍历敌人容器，对半径内敌人造成伤害 + 沿爆炸方向击退
func _explode() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	var center := global_position
	if enemy_spawner.enemies_container:
		for e in enemy_spawner.enemies_container.get_children():
			if e is CharacterBody2D and is_instance_valid(e) and e.has_method("take_damage"):
				var offset: Vector2 = e.global_position - center
				var d: float = offset.length()
				if d <= blast_radius:
					var dir := offset.normalized() if d > 0.001 else Vector2.RIGHT
					e.take_damage(explosion_damage, dir, knockback_force)
	# TODO: 爆炸视觉特效（占位省略）
	call_deferred("queue_free")
