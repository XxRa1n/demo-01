extends Node

## 全局游戏状态
var game_time: float = 0.0
var kills: int = 0
var is_paused: bool = false
var game_over: bool = false
var game_won: bool = false
var player: CharacterBody2D = null

## 时间常量
const WIN_TIME: float = 600.0

## 地图常量
const MAP_SIZE: Vector2 = Vector2(2000.0, 2000.0)
const MAP_CENTER: Vector2 = Vector2(1000.0, 1000.0)

## 信号
signal time_tick(delta: float)
signal kill_counted()
signal game_ended(won: bool)


func _process(delta: float) -> void:
	if is_paused or game_over:
		return
	game_time += delta
	time_tick.emit(delta)
	if game_time >= WIN_TIME:
		game_won = true
		game_over = true
		game_ended.emit(true)


func register_player(p: CharacterBody2D) -> void:
	player = p


func add_kill() -> void:
	kills += 1
	kill_counted.emit()
