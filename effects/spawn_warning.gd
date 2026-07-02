extends Node2D

## 敌人生成预警
## 在敌人真正出现前，先在目标位置播放一段「收缩环 + 脉动填充 + 中心十字」的警告动画，
## 给玩家反应时间，避免敌人在玩家身边凭空生成导致瞬间碰撞。
## 动画结束时通过 warning_finished 信号通知 enemy_spawner 在此处真正生成敌人。
##
## 用 _process 自驱（而非 Tween），这样暂停 / 游戏结束时动画会自然停住，行为正确。

## 默认预警时长（秒）
const DEFAULT_DURATION: float = 0.6

## 目标圈半径（≈ 敌人视觉半径，用于提示生成后敌人占多大空间）
var target_radius: float = 24.0
## 警告色（默认取敌人颜色并提亮）
var warn_color: Color = Color(1.0, 0.85, 0.2)

## 由 enemy_spawner 写入：动画结束时要生成的敌人配置
var spawn_kind: StringName = &"normal"
var spawn_config: Dictionary = {}
var spawn_stat_scale: float = 1.0

## 预警结束 → 通知 spawner 在此位置真正生成敌人（同步信号，回调时本节点仍有效）
signal warning_finished(warning: Node2D)

var _duration: float = DEFAULT_DURATION
var _progress: float = 0.0  # 0..1 动画进度
var _active: bool = false


## 启动预警：记录生成参数并启动自驱动画
func start(p_pos: Vector2, p_kind: StringName, p_config: Dictionary, p_stat_scale: float, p_duration: float = DEFAULT_DURATION) -> void:
	global_position = p_pos
	spawn_kind = p_kind
	spawn_config = p_config
	spawn_stat_scale = p_stat_scale
	_duration = maxf(p_duration, 0.05)

	# 预警圈大小按敌人视觉尺寸放大（敌人越大，提示越显眼）
	target_radius = maxf(float(p_config.get("sprite_size", 24)) * 0.5, 8.0)

	# 警告色：取敌人颜色但向白色提亮 55%，更醒目
	var base_color: Color = p_config.get("color", Color(0.85, 0.2, 0.2))
	warn_color = base_color.lerp(Color(1.0, 1.0, 1.0), 0.55)

	_progress = 0.0
	_active = true
	z_index = 5  # 画在敌人之上、UI 之下
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	# 游戏结束：停止预警并清理（重启时场景整体重载）
	if game_manager.game_over:
		_active = false
		queue_free()
		return
	# 暂停时 _process 默认不跑（继承暂停），这里再加一层保险
	if game_manager.is_paused:
		return
	_progress = minf(_progress + delta / _duration, 1.0)
	queue_redraw()
	if _progress >= 1.0:
		_active = false
		# emit 是同步的：spawner 的回调在本行返回前执行，此时 self 仍有效，可安全读取位置/参数
		warning_finished.emit(self)
		queue_free()


func _draw() -> void:
	if _progress <= 0.0:
		return
	var p := _progress

	# 收缩环：从 1.8× 收到 1.0×，透明度从低到高，逼近时最亮（紧迫感）
	var ring_r := lerpf(target_radius * 1.8, target_radius, p)
	var ring_alpha := lerpf(0.3, 0.95, p)
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 48,
			Color(warn_color.r, warn_color.g, warn_color.b, ring_alpha), 2.5)

	# 脉动填充：整体随进度变浓，叠加快频脉动（整段周期约脉动 4 次）
	var pulse := 0.5 + 0.5 * sin(p * TAU * 4.0)
	var fill_alpha := (0.08 + 0.16 * pulse) * (0.35 + 0.65 * p)
	draw_circle(Vector2.ZERO, target_radius,
			Color(warn_color.r, warn_color.g, warn_color.b, fill_alpha))

	# 中心十字：标示精确落点
	var cross := target_radius * 0.55
	var cross_color := Color(1.0, 1.0, 1.0, lerpf(0.4, 0.85, p))
	draw_line(Vector2(-cross, 0.0), Vector2(cross, 0.0), cross_color, 1.0)
	draw_line(Vector2(0.0, -cross), Vector2(0.0, cross), cross_color, 1.0)
