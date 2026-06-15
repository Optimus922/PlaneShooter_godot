extends Node2D
## Explosion —— 一次性爆炸特效。复刻 Unity 版 Explosion。
## 运行时逐帧换贴图(7 帧),播完自动 queue_free。
## 由 ExplosionManager 实例化并 SpawnAt(pos) 摆位。

const FRAME_COUNT := 7
const FRAME_TIME := 0.05   # 每帧秒数

@onready var sprite: Sprite2D = $Sprite

var _frames: Array[Texture2D] = []
var _index := 0
var _timer := 0.0


func _ready() -> void:
	# 预加载 7 帧(静态路径,Godot 会在导入时生成 .import)
	for i in FRAME_COUNT:
		var path := "res://assets/art/explosion_%d.png" % i
		if ResourceLoader.exists(path):
			_frames.append(load(path))
	if _frames.is_empty():
		queue_free()
		return
	sprite.texture = _frames[0]


func _process(delta: float) -> void:
	_timer += delta
	if _timer < FRAME_TIME:
		return
	_timer -= FRAME_TIME
	_index += 1
	if _index >= _frames.size():
		queue_free()
		return
	sprite.texture = _frames[_index]
