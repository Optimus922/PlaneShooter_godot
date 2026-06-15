extends Node
class_name PlayerBanking
## 玩家倾斜。复刻 Unity 版 PlayerBanking。
## 根据玩家水平移动速度让机身左右倾斜(视觉反馈)。挂在 Player 下,引用其 Sprite。

@export var max_bank_angle: float = 22.0    # 最大倾斜角(度)
@export var bank_speed: float = 10.0        # 倾斜插值速度
@export var velocity_scale: float = 0.04    # 速度→角度的换算系数

@onready var _sprite: Node2D = _resolve_sprite()

var _last_x := 0.0
var _current_angle := 0.0


func _ready() -> void:
	var parent := get_parent()
	if parent is Node2D:
		_last_x = parent.global_position.x


func _resolve_sprite() -> Node2D:
	var parent := get_parent()
	if parent == null:
		return null
	var s := parent.get_node_or_null("Sprite")
	return s if s is Node2D else null


func _process(delta: float) -> void:
	var parent := get_parent()
	if parent == null or not (parent is Node2D) or _sprite == null:
		return
	var px: float = parent.global_position.x
	var vx: float = (px - _last_x) / maxf(delta, 0.0001)
	_last_x = px
	# 目标角度:向右移动→正角(顺时针)。Godot Y 向下,正角度=顺时针。
	var target := clampf(vx * velocity_scale, -max_bank_angle, max_bank_angle)
	_current_angle = lerpf(_current_angle, target, clampf(bank_speed * delta, 0.0, 1.0))
	_sprite.rotation_degrees = _current_angle
