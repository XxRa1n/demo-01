extends Control

## 升级面板控制器
## 监听 upgrade_manager.level_up 信号，暂停游戏，显示 3 个选项

@onready var center_container: CenterContainer = $CenterContainer
@onready var vbox: VBoxContainer = $CenterContainer/VBox
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel

## 等待处理的升级队列
var pending_level_ups: int = 0
var is_showing: bool = false


func _ready() -> void:
	visible = false
	upgrade_manager.level_up.connect(_on_level_up)


func _on_level_up() -> void:
	pending_level_ups += 1
	if not is_showing:
		_show_next_level_up()


func _show_next_level_up() -> void:
	if pending_level_ups <= 0:
		return

	pending_level_ups -= 1
	is_showing = true

	# 暂停游戏
	get_tree().paused = true
	game_manager.is_paused = true

	# 清除旧卡片（保留标题）
	for child in vbox.get_children():
		if child != title_label:
			child.queue_free()

	# 生成 3 个升级选项
	var choices: Array = upgrade_manager.get_upgrade_choices(3)
	var cards_container := HBoxContainer.new()
	cards_container.add_theme_constant_override("separation", 15)
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_container)

	for choice: Dictionary in choices:
		var card := _create_card(choice)
		cards_container.add_child(card)

	visible = true


func _create_card(choice: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_constant_override("margin_left", 15)
	panel.add_theme_constant_override("margin_right", 15)
	panel.add_theme_constant_override("margin_top", 10)
	panel.add_theme_constant_override("margin_bottom", 10)

	# 设置面板样式
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.25, 0.95)
	stylebox.border_color = Color(0.5, 0.5, 0.8, 1.0)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(8)
	stylebox.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", stylebox)

	# 垂直布局
	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(inner_vbox)

	# 名称标签
	var name_label := Label.new()
	name_label.text = choice["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	inner_vbox.add_child(name_label)

	# 描述标签
	var desc_label := Label.new()
	desc_label.text = choice["desc"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	inner_vbox.add_child(desc_label)

	# 按钮交互
	var button := Button.new()
	button.text = "选择"
	button.custom_minimum_size = Vector2(120, 36)
	inner_vbox.add_child(button)

	button.pressed.connect(func():
		_apply_choice(choice)
	)

	# 鼠标悬停高亮
	panel.mouse_entered.connect(func():
		stylebox.bg_color = Color(0.25, 0.25, 0.4, 0.95)
		stylebox.border_color = Color(0.8, 0.8, 1.0, 1.0)
	)
	panel.mouse_exited.connect(func():
		stylebox.bg_color = Color(0.15, 0.15, 0.25, 0.95)
		stylebox.border_color = Color(0.5, 0.5, 0.8, 1.0)
	)

	return panel


func _apply_choice(choice: Dictionary) -> void:
	choice["apply"].call()

	# 隐藏面板，恢复游戏
	visible = false
	get_tree().paused = false
	game_manager.is_paused = false
	is_showing = false

	# 处理排队的升级
	if pending_level_ups > 0:
		# 短暂延迟后显示下一个
		await get_tree().create_timer(0.1).timeout
		_show_next_level_up()
