## 升级触发器：基于分数阈值触发能力选择
extends Node

signal upgrade_triggered()
signal pool_exhausted()

var _selection_count: int = 0
var _next_trigger_score: int = 0
var _last_trigger_score: int = 0
var _pool_exhausted: bool = false
var _fail_count: int = 0
const MAX_FAIL_RETRY: int = 3

var EARLY_THRESHOLDS: Array[int] = [100, 250, 400, 600, 800]
var LATE_INTERVAL: int = 1000

func _ready():
	_reset_thresholds()

func _reset_thresholds():
	_selection_count = 0
	_last_trigger_score = 0
	_pool_exhausted = false
	_fail_count = 0
	if EARLY_THRESHOLDS.size() > 0:
		_next_trigger_score = EARLY_THRESHOLDS[0]
	else:
		_next_trigger_score = LATE_INTERVAL

func _process(_delta):
	if _pool_exhausted:
		return
	if not GameFlowManager.is_playing():
		return

	var current_score = _get_current_score()
	if current_score >= _next_trigger_score:
		_last_trigger_score = current_score
		var result = GameFlowManager.request_card_selection()
		if result:
			_selection_count += 1
			_fail_count = 0
			_advance_threshold()
			_force_show_card_ui()
		else:
			_fail_count += 1
			if GameFlowManager.is_selecting_card():
				_force_show_card_ui()
			if _fail_count >= MAX_FAIL_RETRY:
				_pool_exhausted = true
				pool_exhausted.emit()

func _force_show_card_ui():
	## 直接找到 CardSelectionUI 节点并调用显示
	var card_ui = get_node_or_null("../CardSelectionUI")
	if card_ui and card_ui.has_method("force_show_from_trigger"):
		var options = GameFlowManager.get_current_card_options()
		if options.size() > 0:
			card_ui.force_show_from_trigger(options)

func _advance_threshold():
	if _selection_count < EARLY_THRESHOLDS.size():
		_next_trigger_score = EARLY_THRESHOLDS[_selection_count]
	else:
		var late_index = _selection_count - EARLY_THRESHOLDS.size()
		_next_trigger_score = EARLY_THRESHOLDS[-1] + LATE_INTERVAL * (late_index + 1)

func _get_current_score() -> int:
	var game_manager = get_node_or_null("../GameManager")
	if game_manager and game_manager.get("score") != null:
		return game_manager.score
	return 0

func get_progress() -> float:
	if _pool_exhausted:
		return 1.0
	var current_score = _get_current_score()
	var range_size = _next_trigger_score - _last_trigger_score
	if range_size <= 0:
		return 0.0
	return clampf(float(current_score - _last_trigger_score) / float(range_size), 0.0, 1.0)

func is_pool_exhausted() -> bool:
	return _pool_exhausted

func get_selection_count() -> int:
	return _selection_count

func is_first_selection() -> bool:
	return _selection_count == 0

func get_next_trigger_score() -> int:
	return _next_trigger_score

func reset():
	_reset_thresholds()
