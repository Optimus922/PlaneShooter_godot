extends Node
## ExplosionManager —— 爆炸生成单例(autoload)。复刻 Unity 版 ExplosionManager。
## SpawnAt(pos):在指定世界坐标实例化一个 Explosion 到当前场景。

const EXPLOSION_SCENE := "res://scenes/Explosion.tscn"

var _scene: PackedScene


func _ready() -> void:
	if ResourceLoader.exists(EXPLOSION_SCENE):
		_scene = load(EXPLOSION_SCENE)
	else:
		push_warning("[ExplosionManager] 缺少 Explosion.tscn")


func spawn_at(world_pos: Vector2, scale_mult: float = 1.0) -> void:
	if _scene == null:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var fx := _scene.instantiate()
	tree.current_scene.add_child(fx)
	fx.global_position = world_pos
	if scale_mult != 1.0:
		fx.scale = Vector2.ONE * scale_mult
