extends Area2D
class_name BossPart
## Boss 可受击部位(炮台)。复刻 Unity 版 BossPart。
## 实现 take_damage:玩家子弹命中即扣血,与普通敌机走同一套命中逻辑。
## 被击中闪白;头顶世界空间血条(运行时用 ColorRect 构建);
## 血量归零隐藏自己并回调 Boss(on_destroyed)。

@export var max_health: int = 50
@export var hit_flash_duration: float = 0.06
@export var bar_y_offset: float = -64.0
@export var bar_size: Vector2 = Vector2(80, 12)
@export var full_color: Color = Color(1, 0.3, 0.35)
@export var low_color: Color = Color(1, 0.85, 0.2)

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")
@onready var _flash: SpriteFlash = get_node_or_null("SpriteFlash")
@onready var _shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var current_health: int
var dead := false
var _on_destroyed: Callable = Callable()

var _bar_root: Node2D
var _bar_fill: ColorRect


func _ready() -> void:
	current_health = max_health
	_build_health_bar()
	_update_bar()


func init_part(cb: Callable) -> void:
	_on_destroyed = cb


func is_dead() -> bool:
	return dead


func take_damage(amount: int) -> void:
	if dead:
		return
	current_health = maxi(current_health - amount, 0)
	if _flash:
		_flash.flash()
	_update_bar()
	if current_health <= 0:
		_destroyed()


func _destroyed() -> void:
	dead = true
	ExplosionManager.spawn_at(global_position)
	SfxManager.play_explosion()
	if _shape:
		_shape.set_deferred("disabled", true)
	if _sprite:
		_sprite.visible = false
	if _bar_root:
		_bar_root.visible = false
	if _on_destroyed.is_valid():
		_on_destroyed.call(self)


# ---------- 世界空间血条(运行时用 ColorRect 构建) ----------
func _build_health_bar() -> void:
	_bar_root = Node2D.new()
	_bar_root.position = Vector2(0, bar_y_offset)
	add_child(_bar_root)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.05, 0.08, 0.9)
	bg.size = bar_size
	bg.position = -bar_size * 0.5
	bg.z_index = 50
	_bar_root.add_child(bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = full_color
	_bar_fill.size = bar_size
	_bar_fill.position = -bar_size * 0.5
	_bar_fill.z_index = 51
	_bar_root.add_child(_bar_fill)


func _update_bar() -> void:
	if _bar_fill == null:
		return
	var ratio := float(current_health) / float(max_health) if max_health > 0 else 0.0
	ratio = clampf(ratio, 0.0, 1.0)
	_bar_fill.size = Vector2(bar_size.x * ratio, bar_size.y)
	_bar_fill.color = low_color.lerp(full_color, ratio)
