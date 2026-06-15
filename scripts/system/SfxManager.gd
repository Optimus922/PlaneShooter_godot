extends Node
## SfxManager —— 音效单例(autoload)。复刻 Unity 版 SfxManager。
## 程序生成的 wav 在 res://assets/sfx/。用多个 AudioStreamPlayer 轮询避免打断。

const POOL_SIZE := 6

var _players: Array[AudioStreamPlayer] = []
var _next := 0

var _shoot: AudioStream
var _explosion: AudioStream
var _hit: AudioStream
var _victory: AudioStream


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_shoot = _load("res://assets/sfx/shoot.wav")
	_explosion = _load("res://assets/sfx/explosion.wav")
	_hit = _load("res://assets/sfx/hit.wav")
	_victory = _load("res://assets/sfx/victory.wav")


func _load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("[SfxManager] 缺少音效: %s" % path)
	return null


func _play(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.play()


func play_shoot() -> void:
	_play(_shoot, -10.0)


func play_explosion() -> void:
	_play(_explosion, -4.0)


func play_hit() -> void:
	_play(_hit, -6.0)


func play_victory() -> void:
	_play(_victory, -2.0)
