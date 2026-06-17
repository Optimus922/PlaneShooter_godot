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


## 命中粉尘:子弹打中但未击毁时,在命中点喷一小撮火花/粉尘。
## 用 CPUParticles2D 程序生成,播完自销,无需美术资源。
func spawn_dust(world_pos: Vector2) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var p := CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 8
	p.lifetime = 0.28
	p.local_coords = false
	p.direction = Vector2.UP
	p.spread = 90.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 180.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(1.0, 0.95, 0.7)   # 暖白火花
	tree.current_scene.add_child(p)
	p.global_position = world_pos
	# 播完(lifetime + 余量)自动销毁
	var t := tree.create_timer(0.6)
	t.timeout.connect(p.queue_free)

