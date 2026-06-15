extends Node
class_name SpriteFlash
## SpriteFlash —— 受击闪白助手。复刻 Unity 版 SpriteFlash。
## 挂在敌机/Boss部位下,调用 flash() 让目标 Sprite2D 短暂变白。
## 通过给 Sprite2D 套 flash.gdshader 的 ShaderMaterial 实现。

@export var target_path: NodePath          # 指向要闪白的 Sprite2D(留空则取父节点的 Sprite)
@export var flash_duration: float = 0.06

const SHADER_PATH := "res://assets/shaders/flash.gdshader"

var _mat: ShaderMaterial
var _timer := 0.0
var _flashing := false
var _sprite: CanvasItem


func _ready() -> void:
	_sprite = _resolve_sprite()
	if _sprite == null:
		return
	var shader: Shader = load(SHADER_PATH) if ResourceLoader.exists(SHADER_PATH) else null
	if shader == null:
		return
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("flash_amount", 0.0)
	_sprite.material = _mat
	set_process(false)


func _resolve_sprite() -> CanvasItem:
	if not target_path.is_empty():
		var n := get_node_or_null(target_path)
		if n is CanvasItem:
			return n
	var parent := get_parent()
	if parent == null:
		return null
	if parent is Sprite2D:
		return parent
	var s := parent.get_node_or_null("Sprite")
	return s if s is CanvasItem else null


## 触发一次闪白。
func flash() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("flash_amount", 1.0)
	_timer = flash_duration
	_flashing = true
	set_process(true)


func _process(delta: float) -> void:
	if not _flashing:
		return
	_timer -= delta
	if _timer <= 0.0:
		_mat.set_shader_parameter("flash_amount", 0.0)
		_flashing = false
		set_process(false)
