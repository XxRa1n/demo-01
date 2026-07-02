extends Control

## 升级面板控制器（两步状态机）
## - 游戏开始：监听 game_manager.game_started → 弹「首次武器选择」（is_initial_pick，选完即结束）
## - 每次升级：监听 upgrade_manager.level_up → 武器步(WEAPON) → 天赋步(TALENT)
## - 武器步若满槽且全满级（无新武器可获取+无武器可升级）→ 自动跳过，直接进天赋步
## - 卡片样式沿用原实现，仅 button 回调改为接入状态机（_on_choice_applied）

enum Step { WEAPON, TALENT }

@onready var center_container: CenterContainer = $CenterContainer
@onready var vbox: VBoxContainer = $CenterContainer/VBox
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel

## 升级队列
var pending_level_ups: int = 0
var is_showing: bool = false
var current_step: int = -1
var is_initial_pick: bool = false  # 开始首次武器选择：选完不进天赋步


func _ready() -> void:
	visible = false
	upgrade_manager.level_up.connect(_on_level_up)
	game_manager.game_started.connect(_on_game_started)


# ─── 入口 ────────────────────────────────────────────────────────
func _on_game_started() -> void:
	# 游戏开始：弹一次首次武器选择（玩家此时持有 0 把）
	is_initial_pick = true
	_show_step(Step.WEAPON)


func _on_level_up() -> void:
	pending_level_ups += 1
	if not is_showing:
		_begin_level_up_sequence()


func _begin_level_up_sequence() -> void:
	pending_level_ups -= 1
	is_showing = true
	is_initial_pick = false
	_show_step(Step.WEAPON)


# ─── 步骤渲染 ────────────────────────────────────────────────────
func _show_step(step: int) -> void:
	current_step = step

	# 武器步（非首次选择）若满槽满级 → 自动跳过到天赋步
	if step == Step.WEAPON and not is_initial_pick and upgrade_manager.should_skip_weapon_step():
		_show_step(Step.TALENT)
		return

	# 暂停游戏
	get_tree().paused = true
	game_manager.is_paused = true

	# 标题随步骤切换
	if is_initial_pick:
		title_label.text = "选择初始武装"
	elif step == Step.WEAPON:
		title_label.text = "武器升级"
	else:
		title_label.text = "天赋升级"

	# 取选项
	var choices: Array
	if step == Step.WEAPON:
		choices = upgrade_manager.get_weapon_choices(3)
	else:
		choices = upgrade_manager.get_talent_choices(3)

	# 空池兜底：武器步空 → 进天赋步；天赋步空 → 直接关
	if choices.is_empty():
		if step == Step.WEAPON:
			_show_step(Step.TALENT)
		else:
			_close_panel()
		return

	# 清除旧卡片（保留标题）
	for child in vbox.get_children():
		if child != title_label:
			child.queue_free()

	# 渲染新卡片
	var cards_container := HBoxContainer.new()
	cards_container.add_theme_constant_override("separation", 15)
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_container)
	for choice in choices:
		cards_container.add_child(_create_card(choice))

	visible = true


func _on_choice_applied(choice: Dictionary) -> void:
	choice["apply"].call()
	# 按当前步骤推进状态机
	if current_step == Step.WEAPON:
		if is_initial_pick:
			_close_panel()  # 首次选择选完即结束
		else:
			_show_step(Step.TALENT)  # 升级流程：武器步 → 天赋步
	else:
		_close_panel()  # 天赋步选完 → 本次升级结束


func _close_panel() -> void:
	visible = false
	get_tree().paused = false
	game_manager.is_paused = false
	is_showing = false
	is_initial_pick = false
	current_step = -1
	# 升级队列还有 → 继续
	if pending_level_ups > 0:
		await get_tree().create_timer(0.1).timeout
		_begin_level_up_sequence()


# ─── 卡片渲染（沿用原样式，回调接入状态机）──────────────────────
func _create_card(choice: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_constant_override("margin_left", 15)
	panel.add_theme_constant_override("margin_right", 15)
	panel.add_theme_constant_override("margin_top", 10)
	panel.add_theme_constant_override("margin_bottom", 10)

	# 面板样式
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.25, 0.95)
	stylebox.border_color = Color(0.5, 0.5, 0.8, 1.0)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(8)
	stylebox.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", stylebox)

	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(inner_vbox)

	var name_label := Label.new()
	name_label.text = String(choice["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	inner_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = String(choice["desc"])
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	inner_vbox.add_child(desc_label)

	var button := Button.new()
	button.text = "选择"
	button.custom_minimum_size = Vector2(120, 36)
	inner_vbox.add_child(button)
	button.pressed.connect(_on_choice_applied.bind(choice))

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
