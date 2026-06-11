## 游戏管理器：管理分数、生命值、难度、游戏状态和死亡补偿
extends Node

signal score_gained(amount: int)

var score = 0
var high_score = 0
var game_over_flag = false
var score_timer = 0.0

const SAVE_PATH = "user://fish_game_save.cfg"
const DEATH_COMPENSATION_THRESHOLD = 3
const SHORT_SURVIVAL_TIME = 30.0
var _consecutive_short_runs: int = 0
var _difficulty_reduction: float = 0.0

const MAX_DIFFICULTY = 8.0
const MAX_SPAWN_RATE = 3.0

@onready var score_label = get_node_or_null("../ScoreLabel")
@onready var lives_label = get_node_or_null("../LivesLabel")
@onready var recovery_label = get_node_or_null("../RecoveryLabel")
@onready var combo_label = get_node_or_null("../ComboLabel")
@onready var obstacle_spawner = get_node_or_null("../ObstacleSpawner")
@onready var player = get_node_or_null("../Player")
@onready var upgrade_trigger = get_node_or_null("../UpgradeTrigger")

func _ready():
	_load_high_score()
	
	if upgrade_trigger:
		upgrade_trigger.upgrade_triggered.connect(_on_upgrade_triggered)
		upgrade_trigger.pool_exhausted.connect(_on_pool_exhausted)
	
	GameFlowManager.pool_exhausted_bonus.connect(_on_pool_exhausted_bonus)
	
	if player and player.has_signal("combo_changed"):
		player.combo_changed.connect(_on_combo_changed)

func _process(delta):
	if game_over_flag:
		return
	
	## 选卡时仍需更新生命值显示
	if GameFlowManager.is_selecting_card():
		update_lives_display()
		return
	
	score_timer += delta
	if score_timer >= 0.1:
		var base_score = 2.0
		var dynamic_mult = _get_dynamic_score_multiplier()
		var ability_mult = AbilityManager.get_attribute_value("score_multiplier", 1.0)
		var combo_mult = _get_combo_multiplier()
		var final_mult = dynamic_mult * ability_mult * combo_mult
		var gained = int(base_score * final_mult)
		score += gained
		score_gained.emit(gained)
		update_score_display()
		score_timer = 0.0
	
	update_lives_display()
	_clamp_difficulty()

func _get_dynamic_score_multiplier() -> float:
	const SCORE_THRESHOLD = 500.0
	const MAX_MULTIPLIER = 4.0
	
	if score <= 0:
		return 1.0
	
	var normalized_score = score / SCORE_THRESHOLD
	var raw_mult = 1.0 + log(normalized_score + 1.0) / log(2.0)
	
	return clamp(raw_mult, 1.0, MAX_MULTIPLIER)

func _get_combo_multiplier() -> float:
	if player and player.has_method("get_combo_bonus"):
		return 1.0 + player.get_combo_bonus()
	return 1.0

func _clamp_difficulty():
	if not obstacle_spawner:
		return
	if obstacle_spawner.difficulty > MAX_DIFFICULTY:
		obstacle_spawner.difficulty = MAX_DIFFICULTY
	var min_spawn_interval = 1.0 / MAX_SPAWN_RATE
	if obstacle_spawner.next_spawn_time < min_spawn_interval:
		obstacle_spawner.next_spawn_time = min_spawn_interval

func _on_upgrade_triggered():
	## upgrade_trigger._process 中已经调用了 request_card_selection
	## 这里仅做日志记录，避免重复调用导致状态冲突
	if GameFlowManager.is_playing():
		push_warning("_on_upgrade_triggered called but state is still PLAYING - trigger may have already fired")

func _on_pool_exhausted():
	pass

func _on_combo_changed(count: int, bonus_mult: float):
	if not combo_label:
		return
	
	if count >= 5:
		combo_label.visible = true
		var bonus_pct = int((bonus_mult - 1.0) * 100)
		combo_label.text = "%d 连击  +%d%%" % [count, bonus_pct]
		
		var tween = combo_label.create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		combo_label.visible = false

func _on_pool_exhausted_bonus():
	var player_node = get_node_or_null("../Player")
	if player_node and player_node.has_method("grant_pool_exhausted_bonus"):
		player_node.grant_pool_exhausted_bonus()
	_clear_screen_obstacles()

func _clear_screen_obstacles():
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()

func update_score_display():
	if score_label:
		var dynamic_mult = _get_dynamic_score_multiplier()
		var ability_mult = AbilityManager.get_attribute_value("score_multiplier", 1.0)
		var combo_mult = _get_combo_multiplier()
		var final_mult = dynamic_mult * ability_mult * combo_mult
		var score_text = "Score: " + str(score)
		score_text += " (×%.2f)" % final_mult
		
		if player and player.has_method("get_combo_count"):
			var cc = player.get_combo_count()
			if cc >= 5:
				score_text += "  %d连击" % cc
		
		score_label.text = score_text
		
		var tween = score_label.create_tween()
		tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func update_lives_display():
	if not lives_label or not player:
		return
	
	if not player.has_method("get_lives"):
		return
	
	var current_lives = player.get_lives()
	var max_lives = player.get_max_lives()
	var last_stand_active = player.get("last_stand_active") if player.has_method("get") else false
	
	if last_stand_active:
		lives_label.text = "HP " + str(current_lives) + "/" + str(max_lives) + " [LS]"
		lives_label.modulate = Color(0.2, 1.0, 0.4, 1.0)
	else:
		lives_label.text = "HP " + str(current_lives) + "/" + str(max_lives)
		lives_label.modulate = Color(1, 1, 1, 1)
	
	if recovery_label:
		if current_lives < max_lives:
			var recovery_timer = player.get("life_recovery_timer")
			var recovery_time = player.call("_get_recovery_time") if player.has_method("_get_recovery_time") else 30.0
			if recovery_timer != null and recovery_time > 0.0:
				var remaining = recovery_time - recovery_timer
				if remaining > 0.0:
					recovery_label.text = "恢复 %.0fs" % remaining
				else:
					recovery_label.text = ""
			else:
				recovery_label.text = ""
		else:
			recovery_label.text = ""

func game_over():
	if game_over_flag:
		return
	
	game_over_flag = true
	
	if score > high_score:
		high_score = score
		_save_high_score()
	
	_check_death_compensation()
	
	if obstacle_spawner:
		obstacle_spawner.stop_spawning()
	
	if player and player.has_method("stop"):
		player.stop()
	
	show_game_over_popup()

func _check_death_compensation():
	if not player:
		return
	var survival_time = player.get("survival_time") if player.get("survival_time") != null else 0.0
	if survival_time < SHORT_SURVIVAL_TIME:
		_consecutive_short_runs += 1
	else:
		_consecutive_short_runs = 0
	
	if _consecutive_short_runs >= DEATH_COMPENSATION_THRESHOLD:
		_difficulty_reduction = 0.15
	else:
		_difficulty_reduction = 0.0

func show_game_over_popup():
	var is_new_record = score >= high_score and score > 0
	var record_text = "\n最高分: " + str(high_score)
	if is_new_record:
		record_text += " (新纪录!)"
	
	var popup = AcceptDialog.new()
	popup.dialog_text = "Game Over!\n\n最终得分: " + str(score) + record_text
	popup.title = "游戏结束"
	popup.get_ok_button().text = "再来一次"
	
	var label = popup.get_label()
	if label:
		label.add_theme_font_size_override("font_size", 36)
	
	popup.confirmed.connect(_on_popup_confirmed)
	get_tree().current_scene.add_child(popup)
	popup.popup_centered()

func _on_popup_confirmed():
	if obstacle_spawner:
		obstacle_spawner.reset_difficulty()
		if _difficulty_reduction > 0.0:
			obstacle_spawner.difficulty = 1.0 * (1.0 - _difficulty_reduction)
	if upgrade_trigger:
		upgrade_trigger.reset()
	GameFlowManager.reset()
	AbilityManager.reset()
	get_tree().reload_current_scene()

func restart_game():
	score = 0
	game_over_flag = false
	score_timer = 0.0
	update_score_display()
	if combo_label:
		combo_label.visible = false
	if obstacle_spawner:
		obstacle_spawner.reset_difficulty()
	if upgrade_trigger:
		upgrade_trigger.reset()
	GameFlowManager.reset()
	AbilityManager.reset()

func get_score() -> int:
	return score

func add_score(amount: int):
	var multiplier = AbilityManager.get_attribute_value("score_multiplier", 1.0)
	var gained = int(amount * multiplier)
	score += gained
	score_gained.emit(gained)
	update_score_display()

func get_card_progress() -> float:
	if upgrade_trigger:
		return upgrade_trigger.get_progress()
	return 0.0

func is_pool_exhausted() -> bool:
	if upgrade_trigger:
		return upgrade_trigger.is_pool_exhausted()
	return false

func get_high_score() -> int:
	return high_score

func _load_high_score():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = config.get_value("score", "high_score", 0)

func _save_high_score():
	var config = ConfigFile.new()
	config.set_value("score", "high_score", high_score)
	config.save(SAVE_PATH)
