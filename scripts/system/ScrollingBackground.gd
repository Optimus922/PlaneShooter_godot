extends Node2D
class_name ScrollingBackground
## 滚动星空背景。复刻 Unity 版 ScrollingBackground。
## 用两块 Sprite2D 纹理(开启 region/repeat)纵向滚动循环。
## 这里用 region_enabled + 纹理 repeat,通过移动 region_rect 偏移实现无缝滚动。

@export var scroll_speed: float = 80.0      # 像素/秒
@export var texture: Texture2D

@onready var _layer: Sprite2D = $Layer

var _offset := 0.0


func _ready() -> void:
	if texture == null:
		var path := "res://assets/art/stars.png"
		if ResourceLoader.exists(path):
			texture = load(path)
	if _layer and texture:
		_layer.texture = texture
		_layer.region_enabled = true
		_layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		# 让贴图平铺填满整屏:region 设为视口大小,纹理 repeat 已在导入设置里开启
		var vp := get_viewport_rect().size
		_layer.region_rect = Rect2(0, 0, vp.x, vp.y)
		_layer.centered = false
		_layer.position = Vector2.ZERO


func _process(delta: float) -> void:
	if _layer == null or texture == null:
		return
	_offset += scroll_speed * delta
	var th := texture.get_height()
	if _offset >= th:
		_offset = fmod(_offset, th)
	# 向下滚动:region 起点上移(纹理内容相对下移)
	var vp := get_viewport_rect().size
	_layer.region_rect = Rect2(0, -_offset, vp.x, vp.y)
