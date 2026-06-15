extends Node2D
## Main —— 主场景根。进入/重开时重置全局状态。

func _ready() -> void:
	GameManager.reset()
