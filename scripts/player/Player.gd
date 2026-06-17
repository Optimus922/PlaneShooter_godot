extends Area2D
class_name Player
## 玩家飞机 —— 复刻 Unity 版 PlayerController + PlayerShooter。
## 手指拖动跟随(平滑插值)、屏幕边界 Clamp、移动端自动持续开火。
## 武器系统:单发 / 散弹 / 极光(贯穿) / 跟踪弹,由道具切换。

enum Weapon { SINGLE, SPREAD, AURORA, HOMING }

@export var follow_speed: float = 18.0
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 900.0

# 各武器射速(秒/次)
@export var fire_rate_single: float = 0.18
@export var fire_rate_spread: float = 0.24
@export var fire_rate_aurora: float = 0.14
@export var fire_rate_homing: float = 0.30

@onready var muzzle: Node2D = $Muzzle
@onready var health: PlayerHealth = $PlayerHealth

var _weapon: Weapon = Weapon.SINGLE
var _target_pos: Vector2
var _dragging: bool = false
var _fire_timer: float = 0.0
var _half_extents: Vector2 = Vector2(40, 48)


func _ready() -> void:
	_target_pos = global_position
	add_to_group("player")


## 由道具调用:切换当前武器(持续到死亡/重开)。
func set_weapon(w: int) -> void:
	_weapon = w as Weapon
	_fire_timer = 0.0   # 立刻可射


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
		var t: float = clampf(follow_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(_target_pos, t)
	_clamp_to_screen()


func _clamp_to_screen() -> void:
	var rect: Rect2 = get_viewport_rect()
	global_position.x = clampf(global_position.x, rect.position.x + _half_extents.x, rect.end.x - _half_extents.x)
	global_position.y = clampf(global_position.y, rect.position.y + _half_extents.y, rect.end.y - _half_extents.y)


func _current_fire_rate() -> float:
	match _weapon:
		Weapon.SPREAD: return fire_rate_spread
		Weapon.AURORA: return fire_rate_aurora
		Weapon.HOMING: return fire_rate_homing
		_: return fire_rate_single


func _handle_fire(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = _current_fire_rate()
		_shoot()


func _shoot() -> void:
	if bullet_scene == null:
		return
	match _weapon:
		Weapon.SPREAD:
			# 三发扇形 -18/0/+18 度
			for ang in [-18.0, 0.0, 18.0]:
				_spawn_bullet(Vector2.UP.rotated(deg_to_rad(ang)))
		Weapon.AURORA:
			# 贯穿光束:两道并排贯穿弹
			_spawn_bullet(Vector2.UP, {"pierce": true, "damage": 1, "offset": Vector2(-14, 0)})
			_spawn_bullet(Vector2.UP, {"pierce": true, "damage": 1, "offset": Vector2(14, 0)})
		Weapon.HOMING:
			# 两发跟踪弹,初始略微左右散开
			_spawn_bullet(Vector2.UP.rotated(deg_to_rad(-10.0)), {"homing": true})
			_spawn_bullet(Vector2.UP.rotated(deg_to_rad(10.0)), {"homing": true})
		_:
			_spawn_bullet(Vector2.UP)
	SfxManager.play_shoot()


## 生成一发子弹。opts 可含 pierce/homing/damage/offset。
func _spawn_bullet(dir: Vector2, opts: Dictionary = {}) -> void:
	var b := bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	var off: Vector2 = opts.get("offset", Vector2.ZERO)
	b.global_position = muzzle.global_position + off
	if "pierce" in opts:
		b.pierce = opts["pierce"]
	if "homing" in opts:
		b.homing = opts["homing"]
	if "damage" in opts:
		b.damage = opts["damage"]
	if b.has_method("launch"):
		b.launch(dir, bullet_speed)
