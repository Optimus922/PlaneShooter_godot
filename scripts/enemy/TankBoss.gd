extends Node2D
class_name TankBoss
## 第一关 Boss:坦克本体。复刻 Unity 版 TankBoss。
## 进场→上半屏徘徊+正弦起伏;主炮 N单发+扇形齐射循环,副炮定时瞄准玩家单发;
## 本体不可受击,只有 parts 里的 BossPart(主炮/副炮)能被打,全破即死。

@export var parts: Array[NodePath] = []
@export var hover_y: float = 320.0          # 徘徊中心高度(屏幕坐标 Y)
@export var enter_speed: float = 180.0
@export var wander_speed: float = 150.0
@export var horizontal_padding: float = 90.0
@export var bob_amplitude: float = 48.0
@export var bob_frequency: float = 0.5

@export var enemy_bullet_scene: PackedScene
@export var fire_interval: float = 1.6
@export var muzzle_offset: float = 36.0
@export var main_gun_fan_count: int = 5
@export var main_gun_fan_angle: float = 50.0
@export var main_gun_single_shots: int = 3
@export var main_gun_single_gap: float = 0.35
@export var main_gun_pause: float = 1.0
@export var score_value: int = 500

var _part_nodes: Array[BossPart] = []
var _alive_parts := 0
var _entered := false
var _wander_dir := 1.0
var _fire_timer := 0.0
var _bob_time := 0.0
var _defeated := false
var _on_defeated: Callable = Callable()
var _player: Node2D
var _left_limit := 0.0
var _right_limit := 0.0


func init_boss(cb: Callable) -> void:
	_on_defeated = cb


func _ready() -> void:
	for p in parts:
		var node := get_node_or_null(p)
		if node is BossPart:
			_part_nodes.append(node)
			node.init_part(_on_part_destroyed)
			_alive_parts += 1

	var rect := get_viewport_rect()
	_left_limit = rect.position.x + horizontal_padding
	_right_limit = rect.end.x - horizontal_padding

	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node2D:
		_player = players[0]

	_fire_timer = fire_interval


func _process(delta: float) -> void:
	if _defeated:
		return
	if not _entered:
		global_position.y = move_toward(global_position.y, hover_y, enter_speed * delta)
		if is_equal_approx(global_position.y, hover_y):
			_entered = true
			_main_gun_routine()   # 进场完成后启动主炮循环
		return
	_wander(delta)
	_sub_gun_loop(delta)


func _wander(delta: float) -> void:
	global_position.x += _wander_dir * wander_speed * delta
	if global_position.x <= _left_limit:
		global_position.x = _left_limit
		_wander_dir = 1.0
	elif global_position.x >= _right_limit:
		global_position.x = _right_limit
		_wander_dir = -1.0
	_bob_time += delta
	global_position.y = hover_y + sin(_bob_time * bob_frequency * TAU) * bob_amplitude


## 副炮(parts[1..])定时单发瞄准玩家。
func _sub_gun_loop(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	_fire_timer = fire_interval
	for i in range(1, _part_nodes.size()):
		var p := _part_nodes[i]
		if p == null or p.is_dead():
			continue
		_fire_fan(p.global_position, 1, 0.0)


## 主炮开火节奏:N 发单发 → 停顿 → 1 次扇形齐射 → 停顿 → 循环。
func _main_gun_routine() -> void:
	while not _defeated and not _is_ended():
		var main: BossPart = _part_nodes[0] if not _part_nodes.is_empty() else null
		if main == null or main.is_dead():
			return
		for s in maxi(1, main_gun_single_shots):
			if _defeated or main.is_dead() or _is_ended():
				return
			_fire_fan(main.global_position, 1, 0.0)
			await _wait(main_gun_single_gap)
		await _wait(main_gun_pause)
		if _defeated or main.is_dead() or _is_ended():
			return
		_fire_fan(main.global_position, maxi(1, main_gun_fan_count), main_gun_fan_angle)
		await _wait(main_gun_pause)


func _is_ended() -> bool:
	return not GameManager.is_playing()


func _wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds and not _is_ended() and not _defeated:
		await get_tree().process_frame
		t += get_process_delta_time()


## 从炮口朝玩家方向发射 count 发,在 spread_angle 总张角内均匀分布。
func _fire_fan(turret_pos: Vector2, count: int, spread_angle: float) -> void:
	if enemy_bullet_scene == null:
		return
	var muzzle := turret_pos + Vector2.DOWN * muzzle_offset
	var aim := Vector2.DOWN
	if _player != null:
		aim = (_player.global_position - muzzle).normalized()
	for k in count:
		var t := 0.5 if count == 1 else float(k) / float(count - 1)
		var ang := lerpf(-spread_angle * 0.5, spread_angle * 0.5, t)
		var dir := aim.rotated(deg_to_rad(ang))
		var b := enemy_bullet_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = muzzle
		if b.has_method("launch"):
			b.launch(dir)


func _on_part_destroyed(_part: BossPart) -> void:
	_alive_parts = maxi(0, _alive_parts - 1)
	if _alive_parts <= 0:
		_defeat()


func _defeat() -> void:
	if _defeated:
		return
	_defeated = true
	GameManager.add_score(score_value)
	ExplosionManager.spawn_at(global_position, 1.5)
	for p in _part_nodes:
		if p != null:
			ExplosionManager.spawn_at(p.global_position)
	SfxManager.play_explosion()
	if _on_defeated.is_valid():
		_on_defeated.call()
	queue_free()
