extends Node
## GameManager —— 全局单例(autoload)
## 复刻 Unity 版 System/GameManager.cs:游戏状态、分数、Game Over、Restart。
## 用信号(signal)解耦 HUD —— 对应 Unity 版的事件订阅模式。

enum State { PLAYING, GAME_OVER, VICTORY }

signal score_changed(new_score: int)
signal health_changed(current: int, max: int)
signal game_over
signal victory
signal banner_requested(text: String, duration: float)
signal game_restarted

var state: State = State.PLAYING
var score: int = 0


func _ready() -> void:
	# autoload 在所有场景加载前就绪;切回主场景时由 reset() 归零。
	reset()


## 重置到新一局的初始状态(进入/重开主场景时调用)。
func reset() -> void:
	state = State.PLAYING
	score = 0
	score_changed.emit(score)


## 击杀敌机加分 —— 对应 Enemy.Die() -> GameManager.AddScore(scoreValue)。
func add_score(amount: int) -> void:
	if state != State.PLAYING:
		return
	score += amount
	score_changed.emit(score)


## 玩家血量变化时由 PlayerHealth 通知,转发给 HUD。
func report_health(current: int, max_health: int) -> void:
	health_changed.emit(current, max_health)


## 玩家死亡 —— 进入 Game Over 状态并广播。
func trigger_game_over() -> void:
	if state != State.PLAYING:
		return
	state = State.GAME_OVER
	game_over.emit()


## 所有关卡清完 —— 进入通关胜利。由 EnemySpawner 调用。
func trigger_victory() -> void:
	if state != State.PLAYING:
		return
	state = State.VICTORY
	if SfxManager:
		SfxManager.play_victory()
	victory.emit()


## 显示一条居中的关卡横幅(文本 + 持续秒数)。由 EnemySpawner 调用。
func show_banner(text: String, duration: float) -> void:
	banner_requested.emit(text, duration)


## 重开当前关卡。重载主场景,reset() 会在新场景的 _ready 链里被调用。
func restart_game() -> void:
	game_restarted.emit()
	get_tree().paused = false
	# 延后一帧再换场景,避免在信号回调里直接重载导致的问题。
	get_tree().reload_current_scene.call_deferred()


func is_playing() -> bool:
	return state == State.PLAYING
