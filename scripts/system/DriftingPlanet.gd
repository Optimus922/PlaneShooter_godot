extends Sprite2D
class_name DriftingPlanet
## 缓缓飘过的星球。移速介于远近背景层之间,营造视差中景。
## 从屏幕上方飘入 → 下移 → 飘出底部后,隔随机间隔从顶部以随机 X 重新进入。
## 不像背景那样密集循环,显得是"偶尔飘过一颗"。

@export var speed: float = 60.0          # 介于 far(35) 与 near(110) 之间
@export var respawn_delay_min: float = 6.0
@export var respawn_delay_max: float = 14.0
@export var margin: float = 80.0         # 左右出生留白

var _vp: Vector2
var _wait := 0.0
var _active := true


func _ready() -> void:
	_vp = get_viewport_rect().size
	centered = true
	z_index = -5   # 在背景之上、玩法层之下
	_enter_from_top(true)


func _enter_from_top(initial: bool) -> void:
	var half_h := 0.0
	if texture:
		half_h = texture.get_height() * 0.5 * scale.y
	var x := randf_range(margin, _vp.x - margin)
	# 初次可让它已在画面里一点,之后都从屏幕上方进入
	var y := -half_h
	if initial:
		y = randf_range(-half_h, _vp.y * 0.35)
	global_position = Vector2(x, y)
	_active = true


func _process(delta: float) -> void:
	if not _active:
		_wait -= delta
		if _wait <= 0.0:
			_enter_from_top(false)
		return
	global_position.y += speed * delta
	var half_h := 0.0
	if texture:
		half_h = texture.get_height() * 0.5 * scale.y
	if global_position.y - half_h > _vp.y:
		# 飘出底部 → 等待后重来
		_active = false
		_wait = randf_range(respawn_delay_min, respawn_delay_max)
