## 选卡进度条：显示距离下一次选卡的进度
extends Control

@onready var progress_bar: ProgressBar = $CardProgressBar
@onready var progress_label: Label = $ProgressLabel

var _game_manager: Node = null
var _upgrade_trigger: Node = null

func _ready():
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	_game_manager = get_node_or_null("../GameManager")
	_upgrade_trigger = get_node_or_null("../UpgradeTrigger")
	
	if progress_bar:
		progress_bar.value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.show_percentage = false

func _process(_delta):
	if not _game_manager or not _upgrade_trigger:
		_game_manager = get_node_or_null("../GameManager")
		_upgrade_trigger = get_node_or_null("../UpgradeTrigger")
		return
	
	if _game_manager.is_pool_exhausted():
		if progress_bar:
			progress_bar.modulate = Color(0.5, 0.5, 0.5, 0.3)
		if progress_label:
			progress_label.text = "已空"
			progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
		return
	
	var progress = _upgrade_trigger.get_progress()
	
	if progress_bar:
		progress_bar.value = progress
		if progress >= 0.9:
			progress_bar.modulate = Color(1.0, 0.9, 0.3, 1.0)
		elif progress >= 0.6:
			progress_bar.modulate = Color(0.4, 0.8, 1.0, 1.0)
		else:
			progress_bar.modulate = Color(1, 1, 1, 1)
	
	if progress_label:
		var current_score = _game_manager.get_score()
		var next_score = _upgrade_trigger.get_next_trigger_score()
		var remaining = max(0, next_score - current_score)
		progress_label.text = str(remaining)
		progress_label.add_theme_color_override("font_color", Color(0.8, 0.85, 1.0, 0.9))
