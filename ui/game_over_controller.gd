extends Control

## 游戏结束面板控制器

@onready var result_label: Label = $CenterContainer/VBox/ResultLabel
@onready var stats_label: Label = $CenterContainer/VBox/StatsLabel
@onready var restart_button: Button = $CenterContainer/VBox/RestartButton


func _ready() -> void:
	visible = false
	game_manager.game_ended.connect(_on_game_ended)
	restart_button.pressed.connect(_on_restart)


func _on_game_ended(won: bool) -> void:
	# 短暂延迟后显示结果
	await get_tree().create_timer(1.0).timeout

	# 暂停游戏
	get_tree().paused = true
	game_manager.is_paused = true

	# 设置结果文本
	if won:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		result_label.text = "GAME OVER"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	# 显示统计数据
	var total_seconds: int = int(game_manager.game_time)
	@warning_ignore("integer_division")
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	var time_str := "%d:%02d" % [minutes, seconds]
	var level_str := "Lv.%d" % upgrade_manager.level
	var kill_str := "%d" % game_manager.kills

	stats_label.text = "Time: %s | Level: %s | Kills: %s" % [time_str, level_str, kill_str]

	visible = true


func _on_restart() -> void:
	# 重置所有全局状态
	get_tree().paused = false
	game_manager.is_paused = false
	game_manager.game_over = false
	game_manager.game_won = false
	game_manager.game_time = 0.0
	game_manager.kills = 0
	game_manager.player = null

	upgrade_manager.xp = 0
	upgrade_manager.level = 1
	upgrade_manager.xp_to_next = 8

	# 重新加载场景
	get_tree().reload_current_scene()
