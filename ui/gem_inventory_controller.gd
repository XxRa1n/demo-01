extends Control

## 背包 / 镶嵌面板（代码构建，无 .tscn）：B 键开关。
## 打开时暂停游戏。左栏列出已持有武器 + 宝石槽，右栏列出持有宝石。
## 操作：点持有宝石选中 → 点武器空槽镶嵌；点已镶宝石槽拆卸（宝石回库）。

var _bg: ColorRect
var _weapons_box: VBoxContainer
var _gems_box: VBoxContainer

var _selected_gem: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时仍可交互
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_B:
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	if game_manager.game_over:
		return
	if visible:
		close()
	elif not game_manager.is_paused:  # 升级面板打开时不抢开
		open()


func open() -> void:
	_selected_gem = &""
	_rebuild()
	visible = true
	get_tree().paused = true
	game_manager.is_paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	game_manager.is_paused = false


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.55)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 360)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "背包 / 镶嵌    (B 关闭)"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	vbox.add_child(cols)

	# 左栏：武器 + 槽
	var lw := Label.new()
	lw.text = "武器 / 宝石槽"
	lw.add_theme_font_size_override("font_size", 15)
	cols.add_child(lw)
	_weapons_box = VBoxContainer.new()
	_weapons_box.add_theme_constant_override("separation", 6)
	_weapons_box.custom_minimum_size = Vector2(380, 0)
	cols.add_child(_weapons_box)

	# 右栏：持有宝石
	var rg := Label.new()
	rg.text = "持有宝石"
	rg.add_theme_font_size_override("font_size", 15)
	cols.add_child(rg)
	_gems_box = VBoxContainer.new()
	_gems_box.add_theme_constant_override("separation", 6)
	_gems_box.custom_minimum_size = Vector2(200, 0)
	cols.add_child(_gems_box)

	var hint := Label.new()
	hint.text = "点宝石选中 → 点武器空槽镶嵌；点已镶槽拆卸"
	hint.add_theme_font_size_override("font_size", 13)
	vbox.add_child(hint)


func _rebuild() -> void:
	for c in _weapons_box.get_children():
		c.queue_free()
	for c in _gems_box.get_children():
		c.queue_free()

	var weapons: Array = upgrade_manager.get_owned_weapons()
	if weapons.is_empty():
		var l := Label.new()
		l.text = "(尚无武器)"
		_weapons_box.add_child(l)
	for w in weapons:
		_weapons_box.add_child(_make_weapon_row(w))

	var inv: Dictionary = game_manager.player.gem_inventory if (game_manager.player != null) else {}
	var has_any: bool = false
	for gem_id in inv:
		var cnt: int = int(inv[gem_id])
		if cnt <= 0:
			continue
		has_any = true
		_gems_box.add_child(_make_gem_button(gem_id, cnt))
	if not has_any:
		var l := Label.new()
		l.text = "(空)"
		_gems_box.add_child(l)


func _make_weapon_row(w: Node) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_btn := Button.new()
	name_btn.text = w.display_name
	name_btn.add_theme_font_size_override("font_size", 15)
	row.add_child(name_btn)
	for i in w.max_gem_slots:
		var filled: bool = i < w.gem_slots.size() and w.gem_slots[i] != null
		var gid = w.gem_slots[i] if filled else null
		var dname: String = String(gem_registry.get_def(gid).get("display", "空")) if filled else "空"
		var slot_btn := Button.new()
		slot_btn.text = "[%s]" % dname
		slot_btn.add_theme_font_size_override("font_size", 13)
		slot_btn.pressed.connect(_on_slot_pressed.bind(w, i))
		row.add_child(slot_btn)
	return row


func _make_gem_button(gem_id: Variant, count: int) -> Button:
	var btn := Button.new()
	var d: Dictionary = gem_registry.get_def(gem_id)
	var mark: String = "  ★" if _selected_gem == gem_id else ""
	btn.text = "%s ×%d%s" % [String(d.get("display", String(gem_id))), count, mark]
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_select_gem.bind(gem_id))
	return btn


func _select_gem(gem_id: Variant) -> void:
	_selected_gem = gem_id
	_rebuild()


func _on_slot_pressed(w: Node, slot: int) -> void:
	var filled: bool = slot < w.gem_slots.size() and w.gem_slots[slot] != null
	if filled:
		# 拆卸：宝石回库
		var old = w.unsocket_gem(slot)
		if old != null and game_manager.player != null:
			game_manager.player.gem_inventory[old] = int(game_manager.player.gem_inventory.get(old, 0)) + 1
	elif _selected_gem != &"" and game_manager.player != null:
		# 镶嵌：消耗一颗选中宝石
		var cnt: int = int(game_manager.player.gem_inventory.get(_selected_gem, 0))
		if cnt > 0:
			game_manager.player.gem_inventory[_selected_gem] = cnt - 1
			w.socket_gem(slot, _selected_gem)
	_rebuild()
