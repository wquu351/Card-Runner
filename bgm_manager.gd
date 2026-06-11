## 全局背景音乐管理器（AutoLoad单例，跨场景持久）
extends Node

var _player: AudioStreamPlayer

func _ready():
	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.bus = "Master"
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)

	var stream = load("res://1.mp3")
	if stream:
		_player.stream = stream
		_player.volume_db = -8.0
		stream.loop = true
		_player.play()

func play():
	if _player and not _player.playing:
		_player.play()

func stop():
	if _player:
		_player.stop()

func set_volume(db: float):
	if _player:
		_player.volume_db = clamp(db, -60.0, 0.0)
