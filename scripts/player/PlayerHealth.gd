extends Node2D
class_name PlayerHealth
## 玩家血量 —— 复刻 Unity 版 PlayerHealth(阶段5 升级版)。
## 扣血 + 无敌帧 + 受伤闪烁 + 死亡通知 GameManager。

@export var max_health: int = 5
@export var invincible_duration: float = 1.2   # 受伤后无敌时长(秒)
@export var blink_interval: float = 0.1        # 无敌期间闪烁间隔

@onready var sprite: CanvasItem = get_parent().get_node_or_null("Sprite")

var current_health: int
var _invincible: bool = false
var _invincible_timer: float = 0.0
var _blink_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	# 上报初始血量给 HUD。
	GameManager.report_health(current_health, max_health)


func _process(delta: float) -> void:
	if not _invincible:
		return
	_invincible_timer -= delta
	# 闪烁:周期性切换可见性。
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = blink_interval
		if sprite:
			sprite.visible = not sprite.visible
	if _invincible_timer <= 0.0:
		_end_invincibility()


## 受到伤害。无敌期间忽略;扣血后进入无敌帧;归零则死亡。
func take_damage(amount: int) -> void:
	if _invincible or current_health <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	GameManager.report_health(current_health, max_health)
	SfxManager.play_hit()
	if current_health <= 0:
		_die()
	else:
		_start_invincibility()


func _start_invincibility() -> void:
	_invincible = true
	_invincible_timer = invincible_duration
	_blink_timer = blink_interval


func _end_invincibility() -> void:
	_invincible = false
	if sprite:
		sprite.visible = true


func _die() -> void:
	# 通知全局进入 Game Over,再隐藏/禁用玩家。
	GameManager.trigger_game_over()
	var parent := get_parent()
	if parent:
		parent.set_process(false)
		if parent.has_method("set_process_unhandled_input"):
			parent.set_process_unhandled_input(false)
		parent.visible = false


func is_invincible() -> bool:
	return _invincible
