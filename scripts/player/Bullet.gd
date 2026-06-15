extends Area2D
class_name Bullet
## 玩家子弹 —— 复刻 Unity 版 Bullet.cs。
## 向上飞、命中敌机扣血、出屏回收。
## Godot 没有内置对象池;这里出屏直接 queue_free(),敌机用 free 池亦可。
## 为贴近 Unity 的"复用"语义,这里用简单的命中/出屏即销毁;
## 高频可后续接对象池,逻辑接口(launch/可重用)已留好。

@export var damage: int = 1
@export var lifetime: float = 3.0   # 兜底:超时自动回收,防止漏网

var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0


func _ready() -> void:
	# 命中检测靠 area_entered(敌机也是 Area2D)。
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


## 由发射者调用,设定方向与速度。
func launch(direction: Vector2, speed: float) -> void:
	_velocity = direction.normalized() * speed
	rotation = direction.angle() + PI / 2.0
	_age = 0.0


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_age += delta
	if _age >= lifetime or _is_off_screen():
		queue_free()


func _is_off_screen() -> bool:
	var rect: Rect2 = get_viewport_rect()
	# 上方留一点余量再回收。
	return global_position.y < rect.position.y - 50.0


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _try_hit(target: Node) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
		queue_free()
