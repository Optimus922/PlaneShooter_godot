extends CanvasLayer
class_name GameHUD
## HUD —— 复刻 Unity 版 GameHUD。
## 订阅 GameManager 信号刷新分数/血量;关卡横幅;GameOver 面板 + Victory 面板 + 重开按钮。

@onready var score_label: Label = $Margin/Top/ScoreLabel
@onready var health_label: Label = $Margin/Top/HealthLabel
@onready var banner_label: Label = $BannerLabel
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/Center/VBox/FinalScore
@onready var restart_button: Button = $GameOverPanel/Center/VBox/RestartButton
@onready var victory_panel: Control = $VictoryPanel
@onready var victory_score_label: Label = $VictoryPanel/Center/VBox/VictoryScore
@onready var victory_button: Button = $VictoryPanel/Center/VBox/VictoryRestartButton

var _banner_timer := 0.0


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	GameManager.banner_requested.connect(_on_banner)
	restart_button.pressed.connect(_on_restart_pressed)
	victory_button.pressed.connect(_on_restart_pressed)

	game_over_panel.visible = false
	victory_panel.visible = false
	banner_label.visible = false
	_on_score_changed(GameManager.score)


func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_label.visible = false


func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score


func _on_health_changed(current: int, max_health: int) -> void:
	health_label.text = "HP: %d/%d" % [current, max_health]


func _on_banner(text: String, duration: float) -> void:
	banner_label.text = text
	banner_label.visible = true
	_banner_timer = duration


func _on_game_over() -> void:
	final_score_label.text = "Score: %d" % GameManager.score
	game_over_panel.visible = true


func _on_victory() -> void:
	victory_score_label.text = "Score: %d" % GameManager.score
	victory_panel.visible = true


func _on_restart_pressed() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	GameManager.restart_game()
