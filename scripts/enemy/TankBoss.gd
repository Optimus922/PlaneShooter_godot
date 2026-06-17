extends Node2D
class_name TankBoss
## 赤色要塞风巨型战车 Boss。
## 进场→上半屏徘徊+正弦起伏。外围 6 炮塔各自开火;中央核心舱(core)初始无敌,
## 6 炮塔全破后核心暴露可击杀;核心破才算 Boss 被击败(Defeat)。
## 主炮塔(turrets[0])跑「单发×N→扇形齐射」循环,其余炮塔定时瞄准玩家单发;
## 核心暴露后也朝玩家放环形弹幕。

@export var turrets: Array[NodePath] = []   # 6 个外围炮塔(turrets[0]=中央主炮塔节奏炮)
@export var core_path: NodePath              # 中央核心舱(最终弱点,初始无敌)
@export var hover_y: float = 460.0
@export var enter_speed: float = 220.0
@export var wander_speed: float = 140.0
@export var horizontal_padding: float = 140.0
@export var bob_amplitude: float = 40.0
@export var bob_frequency: float = 0.4

@export var enemy_bullet_scene: PackedScene
@export var fire_interval: float = 1.6
@export var muzzle_offset: float = 40.0
@export var main_gun_fan_count: int = 5
@export var main_gun_fan_angle: float = 50.0
@export var main_gun_single_shots: int = 3
@export var main_gun_single_gap: float = 0.35
@export var main_gun_pause: float = 1.0
@export var core_ring_count: int = 12        # 核心暴露后环形弹幕数
@export var core_fire_interval: float = 2.0
@export var score_value: int = 800

var _turret_nodes: Array[BossPart] = []
var _core: BossPart
var _alive_turrets := 0
var _core_exposed := false
var _entered := false
var _wander_dir := 1.0
var _fire_timer := 0.0
var _core_fire_timer := 0.0
var _bob_time := 0.0
var _defeated := false
var _on_defeated: Callable = Callable()
var _player: Node2D
var _left_limit := 0.0
var _right_limit := 0.0


func init_boss(cb: Callable) -> void:
	_on_defeated = cb


func _ready() -> void:
	for p in turrets:
		var node := get_node_or_null(p)
		if node is BossPart:
			_turret_nodes.append(node)
			node.init_part(_on_turret_destroyed)
			_alive_turrets += 1

	_core = get_node_or_null(core_path) as BossPart
	if _core:
		_core.init_part(_on_core_destroyed)
		# 核心初始无敌(在 .tscn 里也设 invincible=true,双保险)
		_core.invincible = true

	var rect := get_viewport_rect()
	_left_limit = rect.position.x + horizontal_padding
	_right_limit = rect.end.x - horizontal_padding

	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node2D:
		_player = players[0]

	_fire_timer = fire_interval
	_core_fire_timer = core_fire_interval


func _process(delta: float) -> void:
	if _defeated:
		return
	if not _entered:
		global_position.y = move_toward(global_position.y, hover_y, enter_speed * delta)
		if is_equal_approx(global_position.y, hover_y):
			_entered = true
			_main_gun_routine()
		return
	_wander(delta)
	_sub_gun_loop(delta)
	if _core_exposed:
		_core_fire_loop(delta)


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


## 其余炮塔(turrets[1..])定时单发瞄准玩家。
func _sub_gun_loop(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	_fire_timer = fire_interval
	for i in range(1, _turret_nodes.size()):
		var p := _turret_nodes[i]
		if p == null or p.is_dead():
			continue
		_fire_fan(p.global_position, 1, 0.0)


## 核心暴露后:定时朝四周放环形弹幕。
func _core_fire_loop(delta: float) -> void:
	if _core == null or _core.is_dead():
		return
	_core_fire_timer -= delta
	if _core_fire_timer > 0.0:
		return
	_core_fire_timer = core_fire_interval
	_fire_ring(_core.global_position, core_ring_count)


## 主炮塔节奏:N 发单发 → 停顿 → 1 次扇形齐射 → 停顿 → 循环。
func _main_gun_routine() -> void:
	while not _defeated and not _is_ended():
		var main: BossPart = _turret_nodes[0] if not _turret_nodes.is_empty() else null
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
		_spawn_bullet(muzzle, dir)


## 环形弹幕:从 pos 朝四周均匀发射 count 发。
func _fire_ring(pos: Vector2, count: int) -> void:
	if enemy_bullet_scene == null:
		return
	for k in count:
		var ang := TAU * float(k) / float(count)
		var dir := Vector2.RIGHT.rotated(ang)
		_spawn_bullet(pos, dir)


func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	var b := enemy_bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = pos
	if b.has_method("launch"):
		b.launch(dir)


func _on_turret_destroyed(_part: BossPart) -> void:
	_alive_turrets = maxi(0, _alive_turrets - 1)
	if _alive_turrets <= 0 and not _core_exposed:
		_expose_core()


## 6 炮塔全破 → 核心暴露,可击杀。
func _expose_core() -> void:
	_core_exposed = true
	if _core:
		_core.set_vulnerable()
	# 提示横幅(借用 GameManager 横幅)
	GameManager.show_banner("核心暴露!", 1.5)


func _on_core_destroyed(_part: BossPart) -> void:
	_defeat()


func _defeat() -> void:
	if _defeated:
		return
	_defeated = true
	GameManager.add_score(score_value)
	ExplosionManager.spawn_at(global_position, 2.0)
	for p in _turret_nodes:
		if p != null:
			ExplosionManager.spawn_at(p.global_position)
	if _core:
		ExplosionManager.spawn_at(_core.global_position, 1.5)
	SfxManager.play_explosion()
	if _on_defeated.is_valid():
		_on_defeated.call()
	queue_free()
