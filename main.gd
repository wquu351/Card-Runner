## 主场景：游戏入口，初始化背景和核心系统
extends Node2D

@onready var background = $Background
@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel
@onready var recovery_label = $RecoveryLabel
@onready var combo_label = $ComboLabel

var _start_screen_canvas: CanvasLayer = null
var _start_screen: Control = null
var _game_started: bool = false

func _ready():
	if background:
		var viewport = get_viewport()
		var vw = 540
		var vh = 1170
		if viewport:
			vw = int(viewport.get_visible_rect().size.x)
			vh = int(viewport.get_visible_rect().size.y)
		background.texture = TextureGenerator.create_background_texture(vw, vh)
		background.centered = true
		background.position = Vector2(vw / 2.0, vh / 2.0)
	
	## 运行时修正 HUD 标签位置（不依赖 tscn，防止编辑器覆盖）
	call_deferred("_fix_hud_positions")

	_show_start_screen()

var _hud_fixed: bool = false

func _process(_delta):
	## 兜底：第一帧强制修正位置
	if not _hud_fixed:
		_hud_fixed = true
		_fix_hud_positions()

	if not _game_started:
		return

func _fix_hud_positions():
	## 只确保可见性和层级，不修改任何位置（由编辑器控制）
	if score_label:
		score_label.visible = true
		score_label.z_index = 50
	if lives_label:
		lives_label.visible = true
		lives_label.z_index = 50
	if recovery_label:
		recovery_label.visible = true
		recovery_label.z_index = 50
	if combo_label:
		combo_label.visible = true
		combo_label.z_index = 50

func _show_start_screen():
	var scene = preload("res://ui/start_screen/start_screen.tscn")
	_start_screen = scene.instantiate()
	
	_start_screen_canvas = CanvasLayer.new()
	_start_screen_canvas.layer = 200
	_start_screen_canvas.add_child(_start_screen)
	add_child(_start_screen_canvas)
	
	_start_screen.start_game.connect(_on_start_game)
	
	var game_manager = get_node_or_null("GameManager")
	if game_manager:
		game_manager.restart_game()
	
	get_tree().paused = true

func _on_start_game():
	if _start_screen:
		_start_screen.queue_free()
		_start_screen = null
	if _start_screen_canvas:
		_start_screen_canvas.queue_free()
		_start_screen_canvas = null
	
	_game_started = true
	get_tree().paused = false
