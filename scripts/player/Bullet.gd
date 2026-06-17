extends Area2D
class_name Bullet
## 玩家子弹。支持普通直飞、贯穿(pierce)、跟踪(homing)。
## 命中敌机扣血;贯穿弹命中后不消失(但不重复命中同一目标);出屏/超时回收。

@export var damage: int = 1
@export var lifetime: float = 3.0
@export var pierce: bool = false        # 贯穿:命中后不销毁
@export var homing: bool = false        # 跟踪:朝最近敌人转向
@export var turn_rate: float = 6.0      # 跟踪转向速率(rad/s)

var _velocity: Vector2 = Vector2.ZERO
var _speed: float = 900.0
var _age: float = 0.0
var _hit_set := {}   # 贯穿时已命中目标,避免重复扣血


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


## 由发射者调用,设定方向与速度。
func launch(direction: Vector2, speed: float) -> void:
	_speed = speed
	_velocity = direction.normalized() * speed
	rotation = direction.angle() + PI / 2.0
	_age = 0.0


func _physics_process(delta: float) -> void:
	if homing:
		_steer_toward_target(delta)
	global_position += _velocity * delta
	rotation = _velocity.angle() + PI / 2.0
	_age += delta
	if _age >= lifetime or _is_off_screen():
		queue_free()


## 跟踪:找最近的 "enemy" 组目标,平滑转向它。
func _steer_toward_target(delta: float) -> void:
	var nearest: Node2D = null
	var best := INF
	for n in get_tree().get_nodes_in_group("enemy"):
		if n is Node2D and is_instance_valid(n):
			var d := global_position.distance_squared_to(n.global_position)
			if d < best:
				best = d
				nearest = n
	if nearest == null:
		return
	var desired := (nearest.global_position - global_position).normalized()
	var cur := _velocity.normalized()
	# 朝目标方向按 turn_rate 渐转
	var new_dir := cur.slerp(desired, clampf(turn_rate * delta, 0.0, 1.0))
	_velocity = new_dir * _speed


func _is_off_screen() -> bool:
	var rect: Rect2 = get_viewport_rect()
	return (global_position.y < rect.position.y - 50.0
		or global_position.y > rect.end.y + 50.0
		or global_position.x < rect.position.x - 50.0
		or global_position.x > rect.end.x + 50.0)


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _try_hit(target: Node) -> void:
	if not target.has_method("take_damage"):
		return
	if pierce and _hit_set.has(target.get_instance_id()):
		return   # 贯穿弹已打过这个目标,跳过
	target.take_damage(damage, global_position)
	if pierce:
		_hit_set[target.get_instance_id()] = true
	else:
		queue_free()
