extends Area2D
class_name PowerUp
## 武器增强道具。精英小怪死亡掉落,向下飘,玩家拾取后切换武器。
## 三种:散弹(SPREAD)、极光(AURORA)、跟踪弹(HOMING)。

## 对应 Player.Weapon 的值:1=SPREAD, 2=AURORA, 3=HOMING
@export var weapon_type: int = 1
@export var fall_speed: float = 140.0
@export var bob_amplitude: float = 6.0
@export var bob_frequency: float = 2.0

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

const ICONS := {
	1: "res://assets/art/powerup_spread.png",
	2: "res://assets/art/powerup_aurora.png",
	3: "res://assets/art/powerup_homing.png",
}

var _t := 0.0
var _base_x := 0.0
var _base_inited := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	z_index = 5   # 盖在玩法层之上,避免被背景/其他元素遮挡
	scale = Vector2(2.0, 2.0)   # 放大更显眼(16x16 → 32x32)
	_apply_icon()
	# 注意:_base_x 不在 _ready 取 —— 生成方「先 add_child(触发_ready) 再设 global_position」,
	# 此刻 global_position 还没设好(=0),会把道具甩到屏幕最左。延到首帧锁定基准 X。


## 按 weapon_type 切换图标。掉落生成时由 spawner 设好 weapon_type 后调用,或在 _ready 自动应用。
func _apply_icon() -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite")
	var path: String = ICONS.get(weapon_type, ICONS[1])
	if _sprite and ResourceLoader.exists(path):
		_sprite.texture = load(path)


## 供外部在实例化后设置类型(会刷新图标)。
func set_type(t: int) -> void:
	weapon_type = t
	_apply_icon()


func _physics_process(delta: float) -> void:
	if not _base_inited:
		_base_x = global_position.x   # 此时生成方已设好 global_position
		_base_inited = true
	_t += delta
	global_position.y += fall_speed * delta
	# 左右轻微摇摆,显眼一点
	global_position.x = _base_x + sin(_t * bob_frequency * TAU) * bob_amplitude
	if global_position.y > get_viewport_rect().end.y + 40.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var p := area if area is Player else null
	if p == null and area.get_parent() is Player:
		p = area.get_parent()
	if p and p.has_method("set_weapon"):
		p.set_weapon(weapon_type)
		SfxManager.play_hit()   # 暂借音效作为拾取反馈
		queue_free()
