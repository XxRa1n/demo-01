extends Control

@onready var hp_bar: ProgressBar = $TopBar/MarginContainer/HBox/HPContainer/HPBar
@onready var xp_bar: ProgressBar = $TopBar/MarginContainer/HBox/XPContainer/XPBar
@onready var xp_label: Label = $TopBar/MarginContainer/HBox/XPContainer/XPLabel
@onready var timer_label: Label = $TopBar/MarginContainer/HBox/TimerLabel
@onready var kill_label: Label = $TopBar/MarginContainer/HBox/KillLabel


func _ready() -> void:
	# 连接信号
	game_manager.kill_counted.connect(_on_kill_counted)
	upgrade_manager.xp_changed.connect(_on_xp_changed)
	if game_manager.player:
		game_manager.player.damaged.connect(_on_player_damaged)


func _process(_delta: float) -> void:
	# 更新计时器
	var total_seconds: int = int(game_manager.game_time)
	@warning_ignore("integer_division")
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func _on_kill_counted() -> void:
	kill_label.text = "Kill: %d" % game_manager.kills


func _on_player_damaged(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp


func _on_xp_changed(current_xp: int, needed: int, lvl: int) -> void:
	xp_bar.max_value = float(needed)
	xp_bar.value = float(current_xp)
	xp_label.text = "Lv.%d  %d/%d" % [lvl, current_xp, needed]
