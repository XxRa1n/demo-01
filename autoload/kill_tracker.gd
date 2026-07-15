extends Node

## 击杀追踪（autoload）：监听 game_manager.kill_counted，驱动
##   - 嗜血（bloodlust）：玩家有 bloodlust 宝石时，每 20 击杀激活 10s 增益。
##   - 杀敌成长：玩家有 kill_atk / kill_atkspd 宝石时，每 100 击杀永久 +5% 攻击 / 攻速。
## 嗜血增益计时也在本节点 _process 内推进。

var _kills_bloodlust: int = 0
var _kills_atk: int = 0
var _kills_atkspd: int = 0

const BLOODLUST_KILLS: int = 20
const BLOODLUST_DURATION: float = 10.0
const SCALING_STEP: int = 100


func _ready() -> void:
	game_manager.kill_counted.connect(_on_kill)


func _on_kill() -> void:
	var p = game_manager.player
	if p == null or not is_instance_valid(p):
		return
	if p.bloodlust_enabled:
		_kills_bloodlust += 1
		if _kills_bloodlust >= BLOODLUST_KILLS:
			_kills_bloodlust = 0
			p.activate_bloodlust(BLOODLUST_DURATION)
	if p.kill_atk_enabled:
		_kills_atk += 1
		if _kills_atk >= SCALING_STEP:
			_kills_atk -= SCALING_STEP
			p.might *= 1.05
	if p.kill_atkspd_enabled:
		_kills_atkspd += 1
		if _kills_atkspd >= SCALING_STEP:
			_kills_atkspd -= SCALING_STEP
			p.cooldown_mult *= 0.95  # +5% 攻速


func _process(delta: float) -> void:
	var p = game_manager.player
	if p != null and is_instance_valid(p) and p.bloodlust_timer > 0.0:
		p.bloodlust_timer -= delta
		if p.bloodlust_timer <= 0.0:
			p.bloodlust_timer = 0.0
			p.deactivate_bloodlust()
