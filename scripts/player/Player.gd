extends Area2D
class_name Player
## 玩家飞机 —— 复刻 Unity 版 PlayerController + PlayerShooter。
## 手指拖动跟随(平滑插值)、屏幕边界 Clamp、移动端自动持续开火。
## 用 Area2D(对应 Unity 的 Kinematic + Trigger 碰撞语义)。

@export var follow_speed: float = 18.0        # 跟随手指的插值速度
@export var fire_rate: float = 0.18           # 射击间隔(秒)
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 900.0

@onready var muzzle: Node2D = $Muzzle
@onready var health: PlayerHealth = $PlayerHealth

var _target_pos: Vector2
var _dragging: bool = false
var _fire_timer: float = 0.0
var _half_extents: Vector2 = Vector2(40, 48)   # 边界 Clamp 用的飞机半尺寸


func _ready() -> void:
	_target_pos = global_position
	add_to_group("player")
	# 触屏 / 鼠标按下时开始拖动跟随。
	# project.godot 已开启 emulate_touch_from_mouse,编辑器里用鼠标即可测试。


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		if event.pressed:
			_target_pos = event.position
	elif event is InputEventScreenDrag:
		_target_pos = event.position


func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_move(delta)
	_handle_fire(delta)


func _move(delta: float) -> void:
	if _dragging:
		# 平滑插值靠近目标(对应 Unity 的 Lerp)。
		var t: float = clampf(follow_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(_target_pos, t)
	_clamp_to_screen()


func _clamp_to_screen() -> void:
	var rect: Rect2 = get_viewport_rect()
	global_position.x = clampf(global_position.x, rect.position.x + _half_extents.x, rect.end.x - _half_extents.x)
	global_position.y = clampf(global_position.y, rect.position.y + _half_extents.y, rect.end.y - _half_extents.y)


func _handle_fire(delta: float) -> void:
	# 移动端自动持续开火,固定射速。
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_rate
		_shoot()


func _shoot() -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	# 子弹加到场景树顶层,避免随玩家移动;位置在枪口。
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	if bullet.has_method("launch"):
		bullet.launch(Vector2.UP, bullet_speed)
	SfxManager.play_shoot()
