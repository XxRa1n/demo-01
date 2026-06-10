extends Node2D

const PlayerScene = preload("res://scenes/player.tscn")

@onready var game_world: Node2D = $GameWorld
@onready var enemies_container: Node2D = $GameWorld/Enemies
@onready var projectiles_container: Node2D = $GameWorld/Projectiles
@onready var xp_gems_container: Node2D = $GameWorld/XPGems
@onready var hud: Control = $UILayer/HUD


func _ready() -> void:
	var player = PlayerScene.instantiate()
	game_world.add_child(player)
	# 等待玩家 ready 后连接信号
	await get_tree().process_frame
	player.damaged.connect(hud._on_player_damaged)
