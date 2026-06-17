extends Area2D
class_name Enemy
## 敌机 —— 复刻 Unity 版 Enemy.cs。
## 向下移动、血量/受伤/死亡、撞玩家造成 contact_damage、出屏回收。
## 死亡时调用 GameManager.add_score(score_value)(对应 Unity Enemy.Die)。

@export var move_speed: float = 220.0
@export var max_health: int = 3
@export var contact_damage: int = 1
@export var score_value: int = 100

## 精英小怪参数
@export var elite_health: int = 10
@export var elite_score: int = 300
@export var elite_color: Color = Color(0.9, 0.25, 0.25)

var current_health: int
var _is_elite := false

@onready var _flash: SpriteFlash = get_node_or_null("SpriteFlash")
@onready var _sprite: CanvasItem = get_node_or_null("Sprite")

var _on_returned: Callable = Callable()
var _counted := false


## 由 EnemySpawner 注入:敌机离场(击毁/出屏/撞玩家)时回调一次,用于波次存活计数。
func set_on_returned(cb: Callable) -> void:
	_on_returned = cb


## 设为精英小怪:高血量 + 红色主体。生成时由 spawner 调用(需在 add_child 后)。
func make_elite() -> void:
	_is_elite = true
	max_health = elite_health
	score_value = elite_score
	current_health = max_health
	if _sprite == null:
		_sprite = get_node_or_null("Sprite")
	if _sprite:
		_sprite.modulate = elite_color


## 离场:先通知生成器(每架一次),再销毁。
func _return() -> void:
	if not _counted:
		_counted = true
		if _on_returned.is_valid():
			_on_returned.call()
	queue_free()


func _ready() -> void:
	current_health = max_health
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position.y += move_speed * delta
	if _is_off_screen():
		# 出屏回收。
		_return()


func _is_off_screen() -> bool:
	var rect: Rect2 = get_viewport_rect()
	return global_position.y > rect.end.y + 80.0


## 被子弹命中扣血。hit_pos 为命中世界坐标(用于粉尘特效),默认取自身位置。
func take_damage(amount: int, hit_pos: Vector2 = Vector2.INF) -> void:
	if current_health <= 0:
		return
	current_health -= amount
	if _flash:
		_flash.flash()
	if current_health <= 0:
		die()
	else:
		# 未死:命中点喷粉尘火花
		var pos := hit_pos if hit_pos != Vector2.INF else global_position
		ExplosionManager.spawn_dust(pos)


func die() -> void:
	GameManager.add_score(score_value)
	ExplosionManager.spawn_at(global_position)
	SfxManager.play_explosion()
	if _is_elite:
		_drop_powerup()
	_return()


## 精英死亡掉落随机武器道具(散弹/极光/跟踪弹)。
func _drop_powerup() -> void:
	var path := "res://scenes/PowerUp.tscn"
	if not ResourceLoader.exists(path):
		push_warning("[Enemy] 缺少 PowerUp.tscn")
		return
	var scene: PackedScene = load(path)
	var item := scene.instantiate()
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	tree.current_scene.add_child(item)
	item.global_position = global_position
	# 1=SPREAD 2=AURORA 3=HOMING,随机一种
	var t := randi() % 3 + 1
	if item.has_method("set_type"):
		item.set_type(t)
	else:
		item.weapon_type = t


func _on_area_entered(area: Area2D) -> void:
	_try_hit_player(area)


func _on_body_entered(body: Node) -> void:
	_try_hit_player(body)


## 撞到玩家:对玩家血量造成 contact_damage,自身销毁。
func _try_hit_player(target: Node) -> void:
	# 玩家身上的 PlayerHealth 节点负责扣血。
	var ph: Node = null
	if target is Player:
		ph = target.get_node_or_null("PlayerHealth")
	elif target.has_method("take_damage") and target.get_parent() is Player:
		ph = target
	if ph and ph.has_method("take_damage"):
		ph.take_damage(contact_damage)
		_return()
