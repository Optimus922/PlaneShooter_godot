extends Area2D
class_name EnemyBullet
## 敌方子弹。复刻 Unity 版 EnemyBullet。由 Boss 炮台发射,朝设定方向飞行,命中玩家扣血。
## 出屏回收。Boss 朝玩家瞄准,故任意方向飞行,按"离开相机范围+余量"判定回收。

@export var speed: float = 420.0
@export var damage: int = 1
@export var screen_margin: float = 120.0

var _direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)


## 发射:设定飞行方向(归一化)。
func launch(dir: Vector2) -> void:
	_direction = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.DOWN
	rotation = _direction.angle() - PI / 2.0


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	if _is_off_screen():
		queue_free()


func _is_off_screen() -> bool:
	var rect: Rect2 = get_viewport_rect()
	return (global_position.y < rect.position.y - screen_margin
		or global_position.y > rect.end.y + screen_margin
		or global_position.x < rect.position.x - screen_margin
		or global_position.x > rect.end.x + screen_margin)


func _on_hit(target: Node) -> void:
	var ph: Node = null
	if target is Player:
		ph = target.get_node_or_null("PlayerHealth")
	elif target.has_method("take_damage") and target.get_parent() is Player:
		ph = target
	if ph and ph.has_method("take_damage"):
		ph.take_damage(damage)
		queue_free()
