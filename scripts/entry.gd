extends Control

## 开局入口界面（标题屏）
## - 作为项目主场景，启动后先停留在此
## - 显示期间冻结全局计时（game_manager.is_paused = true），避免玩家停留期间 game_time 累加
## - 「开始游戏」解冻并切换到 main.tscn
## - 「设置」弹出内嵌面板（全屏切换 / 主音量）
## - 「退出游戏」退出应用
## - 全屏/音量设置经 ConfigFile 持久化到 user://settings.cfg，跨会话保留

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const KEY_MASTER := "master"
const SECTION_VIDEO := "video"
const KEY_FULLSCREEN := "fullscreen"

@onready var start_button: Button = $CenterContainer/VBox/StartButton
@onready var settings_button: Button = $CenterContainer/VBox/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBox/QuitButton
@onready var settings_panel: Control = $SettingsPanel
@onready var fullscreen_button: Button = $SettingsPanel/CenterContainer/VBox/FullscreenButton
@onready var volume_slider: HSlider = $SettingsPanel/CenterContainer/VBox/VolumeSlider
@onready var settings_back_button: Button = $SettingsPanel/CenterContainer/VBox/BackButton


func _ready() -> void:
	# entry 显示期间冻结全局游戏逻辑（autoload game_manager 已就绪）
	game_manager.is_paused = true
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	fullscreen_button.pressed.connect(_on_fullscreen_toggled)
	settings_back_button.pressed.connect(_on_settings_back)
	volume_slider.value_changed.connect(_on_volume_changed)

	settings_panel.visible = false
	# 先应用已保存的设置（全屏/音量），再让滑块/按钮反映当前状态
	_apply_saved_settings()
	_sync_controls_from_state()


func _on_start_pressed() -> void:
	# 解冻后切换到对局场景；main._ready 会创建玩家并 emit game_started
	game_manager.is_paused = false
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	settings_panel.visible = true


func _on_settings_back() -> void:
	settings_panel.visible = false


func _on_fullscreen_toggled() -> void:
	# 在窗口/全屏之间切换
	var currently_windowed := DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
	_set_fullscreen(currently_windowed)
	_sync_controls_from_state()
	_save_setting(SECTION_VIDEO, KEY_FULLSCREEN, _is_fullscreen())


func _on_volume_changed(value: float) -> void:
	_apply_volume(value)
	_save_setting(SECTION_AUDIO, KEY_MASTER, value)


# ─── 设置应用 / 持久化 ───────────────────────────────────────────
func _apply_saved_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return  # 首次运行无配置文件，保持默认
	_apply_volume(float(cfg.get_value(SECTION_AUDIO, KEY_MASTER, 1.0)))
	_set_fullscreen(bool(cfg.get_value(SECTION_VIDEO, KEY_FULLSCREEN, false)))


func _sync_controls_from_state() -> void:
	# 滑块反映当前 Master 总线音量（no_signal 避免触发 value_changed 回调重入）
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(bus_idx)))
	# 按钮文字显示「即将切换到的目标模式」，更直观
	fullscreen_button.text = "切换窗口" if _is_fullscreen() else "切换全屏"


func _apply_volume(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))


func _set_fullscreen(fullscreen: bool) -> void:
	var target := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target:
		DisplayServer.window_set_mode(target)


func _is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func _save_setting(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # 文件可能尚不存在，忽略错误以保留已写入的键
	cfg.set_value(section, key, value)
	cfg.save(SETTINGS_PATH)
