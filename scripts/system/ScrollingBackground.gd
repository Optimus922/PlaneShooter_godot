extends Node2D
class_name ScrollingBackground
## 双层视差星空背景。远层(far)慢、近层(near)快,各自纵向无缝循环。
## 用「每层两块贴图上下接力」做无缝滚动,不依赖纹理导入的 repeat 设置(更稳)。
##
## 贴图 1080x960。每层两块 Sprite2D 竖直拼接,整体向下滚;
## 某一块完全移出屏幕底部后,跳回另一块的上方,如此循环。
##
## 节点结构(.tscn 里需要):
##   ScrollingBackground (本脚本)
##     Far  : Sprite2D  (texture=bg_far)   —— 仅作模板,运行时复制成两块
##     Near : Sprite2D  (texture=bg_near)

@export var far_texture: Texture2D
@export var near_texture: Texture2D
@export var far_speed: float = 50.0
@export var near_speed: float = 150.0

var _vp: Vector2
var _far_tiles: Array[Sprite2D] = []
var _near_tiles: Array[Sprite2D] = []
var _far_h := 0.0
var _near_h := 0.0


func _ready() -> void:
	z_index = -10
	_vp = get_viewport_rect().size
	if far_texture == null and ResourceLoader.exists("res://assets/art/bg_far.png"):
		far_texture = load("res://assets/art/bg_far.png")
	if near_texture == null and ResourceLoader.exists("res://assets/art/bg_near.png"):
		near_texture = load("res://assets/art/bg_near.png")
	# 移除 .tscn 里的模板 Sprite,改由脚本生成两块
	for child in get_children():
		child.queue_free()
	_far_tiles = _make_layer(far_texture, -2)
	_near_tiles = _make_layer(near_texture, -1)
	if far_texture:
		_far_h = far_texture.get_height()
	if near_texture:
		_near_h = near_texture.get_height()


func _make_layer(tex: Texture2D, z: int) -> Array[Sprite2D]:
	var tiles: Array[Sprite2D] = []
	if tex == null:
		return tiles
	var h := float(tex.get_height())
	# 需要覆盖整屏 + 上方留一块备用(向下滚时从顶部补位)
	var count := int(ceil(_vp.y / h)) + 1
	for i in count:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.z_index = z
		# 从 -h 起向下铺:最上面一块在屏幕外上方,作补位用
		s.position = Vector2(0, (i - 1) * h)
		add_child(s)
		tiles.append(s)
	return tiles


func _process(delta: float) -> void:
	_scroll(_far_tiles, _far_h, far_speed * delta)
	_scroll(_near_tiles, _near_h, near_speed * delta)


func _scroll(tiles: Array[Sprite2D], h: float, step: float) -> void:
	if tiles.is_empty() or h <= 0.0:
		return
	for s in tiles:
		s.position.y += step
	# 整块移出屏幕底部 → 跳到当前最高一块的上方
	for s in tiles:
		if s.position.y >= _vp.y:
			var min_y := INF
			for other in tiles:
				min_y = minf(min_y, other.position.y)
			s.position.y = min_y - h
