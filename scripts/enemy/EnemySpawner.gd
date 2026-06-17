extends Node2D
class_name EnemySpawner
## 敌机生成器(阶段8:波次关卡系统 + 多关串联 + 关卡横幅 + Boss)。
## 复刻 Unity 版 EnemySpawner。用 await/计时替代协程。
##
## 流程:按 levels 顺序执行 → 每关开场「第X关」横幅 → 逐波刷怪(整波击毁才过波)
## → 若配 Boss 则「警告!Boss来袭」+ 出 Boss 等被击杀 → 「第X关通过」→ 下一关。
## 全部清完 → GameManager.trigger_victory()。

@export var levels: Array[LevelData] = []
@export var enemy_scene: PackedScene          # 默认敌机(波次未指定 override 时用)
@export var banner_duration: float = 2.0
@export var boss_warning_duration: float = 2.0
@export var between_levels_gap: float = 1.0
@export var spawn_height_offset: float = 60.0  # 顶部出生额外高度(屏外)
@export var horizontal_padding: float = 60.0

var _alive_count := 0      # 本波在场敌机数
var _running := false


func _ready() -> void:
	if levels.is_empty():
		push_warning("[EnemySpawner] 未配置 levels,不会刷怪。")
		return
	_run_campaign()


func _is_game_ended() -> bool:
	return not GameManager.is_playing()


## 等待 seconds 秒(可被游戏结束打断)。
func _wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds and not _is_game_ended():
		await get_tree().process_frame
		t += get_process_delta_time()


## 按关卡列表顺序执行整场。
func _run_campaign() -> void:
	_running = true
	# 等一帧,确保 HUD 已订阅 banner 信号,首条横幅不丢。
	await get_tree().process_frame

	for i in levels.size():
		if _is_game_ended():
			return
		var level := levels[i]
		if level == null or level.waves.is_empty():
			continue
		var level_number := i + 1

		GameManager.show_banner("第 %d 关" % level_number, banner_duration)
		await _wait(banner_duration)
		if _is_game_ended():
			return

		await _run_level(level)
		if _is_game_ended():
			return

		# 本关 Boss
		if level.boss_scene != null:
			GameManager.show_banner("警告!Boss 来袭", boss_warning_duration)
			await _wait(boss_warning_duration)
			if _is_game_ended():
				return
			await _run_boss(level.boss_scene)
			if _is_game_ended():
				return

		GameManager.show_banner("第 %d 关通过" % level_number, banner_duration)
		await _wait(banner_duration)
		if _is_game_ended():
			return

		if i < levels.size() - 1 and between_levels_gap > 0.0:
			await _wait(between_levels_gap)

	# 全部关卡清完 → 通关胜利
	if not _is_game_ended():
		GameManager.trigger_victory()


## 按波次表执行一整关。
func _run_level(level: LevelData) -> void:
	for wave in level.waves:
		if _is_game_ended():
			return
		var prefab: PackedScene = wave.enemy_override if wave.enemy_override != null else enemy_scene
		await _run_wave(wave, prefab)
		if _is_game_ended():
			return
		if wave.delay_after_clear > 0.0:
			await _wait(wave.delay_after_clear)


## 执行单波:先零散刷怪,再刷一个编队(横排/纵列),编队里含一架精英(掉道具)。
## 全部离场(击毁/出屏)才过波。
func _run_wave(wave: WaveData, prefab: PackedScene) -> void:
	_alive_count = 0
	# 零散小怪(无精英)
	for i in wave.enemy_count:
		if _is_game_ended():
			return
		_spawn_one(prefab, false)
		if wave.spawn_interval > 0.0:
			await _wait(wave.spawn_interval)
	# 编队(横排或纵列,含一架精英)
	if not _is_game_ended():
		await _wait(0.6)
		_spawn_formation(prefab)
	# 等本波全部离场
	while _alive_count > 0 and not _is_game_ended():
		await get_tree().process_frame


## 生成一个编队:随机横排并列 或 纵列鱼贯,其中一架是精英。
func _spawn_formation(prefab: PackedScene) -> void:
	var count := 5
	var elite_index := randi() % count
	var rect := get_viewport_rect()
	var horizontal := randf() < 0.5
	if horizontal:
		# 横排并列:屏幕中部均匀分布的 X,同一时刻进入
		var span := rect.size.x - horizontal_padding * 2.0
		for i in count:
			if _is_game_ended():
				return
			var x := rect.position.x + horizontal_padding + span * float(i) / float(count - 1)
			_spawn_at(prefab, Vector2(x, -spawn_height_offset), i == elite_index)
	else:
		# 纵列鱼贯:同一 X,依次下来
		var x := randf_range(rect.position.x + horizontal_padding, rect.end.x - horizontal_padding)
		for i in count:
			if _is_game_ended():
				return
			_spawn_at(prefab, Vector2(x, -spawn_height_offset - i * 90.0), i == elite_index)


## 生成本关 Boss,等待其被击杀。
func _run_boss(boss_scene: PackedScene) -> void:
	if boss_scene == null:
		return
	var boss := boss_scene.instantiate()
	var rect := get_viewport_rect()
	# 敌机离场回调要在入树前设;Boss 入树后再摆位。
	get_tree().current_scene.add_child(boss)
	# 顶部中央上方生成,Boss 自己移动进场。
	boss.global_position = Vector2(rect.size.x * 0.5, -120.0)

	var defeated := {"v": false}
	if boss.has_method("init_boss"):
		boss.init_boss(func(): defeated["v"] = true)
	else:
		defeated["v"] = true
	while not defeated["v"] and not _is_game_ended():
		await get_tree().process_frame


func _spawn_one(prefab: PackedScene, is_elite: bool = false) -> void:
	if prefab == null:
		return
	var rect := get_viewport_rect()
	var x := randf_range(rect.position.x + horizontal_padding, rect.end.x - horizontal_padding)
	_spawn_at(prefab, Vector2(x, -spawn_height_offset), is_elite)


## 在指定位置生成一架敌机。
func _spawn_at(prefab: PackedScene, pos: Vector2, is_elite: bool) -> void:
	if prefab == null:
		return
	var enemy := prefab.instantiate()
	# 敌机离场时回调,减少存活计数(用于波次判定)。入树前设回调,入树后摆位。
	if enemy.has_method("set_on_returned"):
		enemy.set_on_returned(_on_enemy_returned)
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos
	if is_elite and enemy.has_method("make_elite"):
		enemy.make_elite()
	_alive_count += 1


func _on_enemy_returned() -> void:
	_alive_count = maxi(0, _alive_count - 1)
