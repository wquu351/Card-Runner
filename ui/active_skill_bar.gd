## 主动技能栏：底部横向排列，金色光晕，可点击触发，按获取顺序动态排序
extends Control

var _skill_buttons: Dictionary = {}
var _player: Node2D = null
var _classifier = null
var _acquired_active_skills: Array = []

const BUTTON_SIZE = Vector2(95, 75)
const BUTTON_GAP = 12
const GLOW_WIDTH = 4

func _ready():
	z_index = 10
	
	_classifier = load("res://ui/skill_classifier.gd").new()
	add_child(_classifier)
	
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	if AbilityManager:
		AbilityManager.ability_added.connect(_on_ability_added)
		AbilityManager.ability_stack_changed.connect(_on_ability_changed)
	
	_refresh_acquired_list()
	_build_active_buttons()

func _on_ability_added(ability, stacks):
	if ability and _classifier.is_active_skill(ability.ability_id):
		if not _acquired_active_skills.has(ability.ability_id):
			_acquired_active_skills.append(ability.ability_id)
			call_deferred("_build_active_buttons")

func _on_ability_changed(ability_id: String, new_stacks: int):
	if new_stacks <= 0 and _acquired_active_skills.has(ability_id):
		_acquired_active_skills.erase(ability_id)
		call_deferred("_build_active_buttons")
	elif new_stacks > 0 and not _acquired_active_skills.has(ability_id):
		if _classifier.is_active_skill(ability_id):
			_acquired_active_skills.append(ability_id)
			call_deferred("_build_active_buttons")

func _refresh_acquired_list():
	_acquired_active_skills.clear()
	if not AbilityManager:
		return
	
	var owned = AbilityManager.get_all_owned_abilities()
	for ability_id in owned:
		if owned[ability_id] > 0 and _classifier.is_active_skill(ability_id):
			_acquired_active_skills.append(ability_id)

func _build_active_buttons():
	for child in get_children():
		if child is Button or child.name.begins_with("Active_"):
			child.queue_free()
	_skill_buttons.clear()
	
	var active_skills = _acquired_active_skills.duplicate()
	var total_width = active_skills.size() * (BUTTON_SIZE.x + BUTTON_GAP) - BUTTON_GAP if active_skills.size() > 0 else 0
	var start_x = (size.x - total_width) / 2.0 if size.x > 0 else 0.0
	var start_y = (size.y - BUTTON_SIZE.y) / 2.0 if size.y > 0 else 0.0
	
	for i in range(active_skills.size()):
		var skill_id = active_skills[i]
		var def = _classifier.get_skill_definition(skill_id)
		if def.is_empty():
			continue
		
		var button = Button.new()
		button.name = "Active_" + skill_id
		button.custom_minimum_size = BUTTON_SIZE
		button.position = Vector2(start_x + i * (BUTTON_SIZE.x + BUTTON_GAP), start_y)
		button.size = BUTTON_SIZE
		button.text = ""
		button.disabled = true
		button.z_index = 5
		button.pressed.connect(_on_skill_pressed.bind(skill_id))
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.18, 0.18, 0.25, 0.95)
		style_normal.border_color = def["glow_color"]
		style_normal.border_color.a = 0.85
		style_normal.set_border_width_all(GLOW_WIDTH)
		style_normal.set_corner_radius_all(10)
		button.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.25, 0.25, 0.32, 0.98)
		style_hover.border_color = def["glow_color"]
		style_hover.border_color.a = 1.0
		style_hover.set_border_width_all(GLOW_WIDTH + 2)
		style_hover.set_corner_radius_all(10)
		button.add_theme_stylebox_override("hover", style_hover)
		
		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = Color(0.15, 0.15, 0.2, 1.0)
		style_pressed.border_color = Color(1.0, 1.0, 1.0, 1.0)
		style_pressed.set_border_width_all(GLOW_WIDTH)
		style_pressed.set_corner_radius_all(10)
		button.add_theme_stylebox_override("pressed", style_pressed)
		
		var style_disabled = StyleBoxFlat.new()
		style_disabled.bg_color = Color(0.1, 0.1, 0.12, 0.7)
		style_disabled.border_color = Color(0.3, 0.3, 0.35, 0.4)
		style_disabled.set_border_width_all(2)
		style_disabled.set_corner_radius_all(10)
		button.add_theme_stylebox_override("disabled", style_disabled)
		
		var icon_label = Label.new()
		icon_label.name = "IconLabel"
		icon_label.text = def["icon_text"]
		icon_label.add_theme_font_size_override("font_size", 24)
		icon_label.add_theme_color_override("font_color", def["color"])
		icon_label.anchor_left = 0.5
		icon_label.anchor_top = 0.15
		icon_label.anchor_right = 0.5
		icon_label.anchor_bottom = 0.5
		icon_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		icon_label.grow_vertical = Control.GROW_DIRECTION_BOTH
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = def["display_name"].left(4)
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1.0))
		name_label.anchor_left = 0.05
		name_label.anchor_top = 0.62
		name_label.anchor_right = 0.95
		name_label.anchor_bottom = 0.78
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(name_label)
		
		var cooldown_bar = ProgressBar.new()
		cooldown_bar.name = "CooldownBar"
		cooldown_bar.anchor_left = 0.08
		cooldown_bar.anchor_top = 0.82
		cooldown_bar.anchor_right = 0.92
		cooldown_bar.anchor_bottom = 0.94
		cooldown_bar.max_value = 1.0
		cooldown_bar.value = 0.0
		cooldown_bar.show_percentage = false
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = def["glow_color"]
		fill_style.set_corner_radius_all(3)
		cooldown_bar.add_theme_stylebox_override("fill", fill_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
		bg_style.set_corner_radius_all(3)
		cooldown_bar.add_theme_stylebox_override("background", bg_style)
		
		button.add_child(cooldown_bar)
		
		add_child(button)
		_skill_buttons[skill_id] = {
			"button": button,
			"icon_label": icon_label,
			"name_label": name_label,
			"cooldown_bar": cooldown_bar,
			"def": def
		}

func _process(_delta):
	if not _player or not is_instance_valid(_player):
		_player = get_tree().current_scene.get_node_or_null("Player")
	if not _player:
		return
	
	for skill_id in _skill_buttons:
		var data = _skill_buttons[skill_id]
		var button = data["button"]
		var cooldown_bar = data["cooldown_bar"]
		
		var cooldown_ratio = _get_cooldown_ratio(skill_id)
		var can_use = cooldown_ratio >= 1.0
		
		button.disabled = not can_use
		
		if cooldown_bar:
			cooldown_bar.value = cooldown_ratio

func _get_cooldown_ratio(skill_id: String) -> float:
	if not _player:
		return 1.0
	
	match skill_id:
		"decoy":
			var cd_timer = _player.get("decoy_cooldown_timer") if _player.has_method("get") else null
			var cd_max = _player.get("decoy_cooldown") if _player.has_method("get") else null
			if cd_timer != null and cd_max and cd_max > 0:
				return clamp(1.0 - (cd_timer / cd_max), 0.0, 1.0)
		"time_slow":
			var cd_timer = _player.get("time_slow_cooldown_timer") if _player.has_method("get") else null
			var cd_max = _player.get("time_slow_cooldown") if _player.has_method("get") else null
			if cd_timer != null and cd_max and cd_max > 0:
				return clamp(1.0 - (cd_timer / cd_max), 0.0, 1.0)
		"swap":
			var cd_timer = _player.get("swap_cooldown_timer") if _player.has_method("get") else null
			var cd_max = _player.get("swap_cooldown") if _player.has_method("get") else null
			if cd_timer != null and cd_max and cd_max > 0:
				return clamp(1.0 - (cd_timer / cd_max), 0.0, 1.0)
	return 1.0

func _on_skill_pressed(skill_id: String):
	if not _player or not is_instance_valid(_player):
		return
	
	match skill_id:
		"decoy":
			if _player.has_method("_trigger_decoy"):
				_player._trigger_decoy()
		"time_slow":
			if _player.has_method("_trigger_time_slow"):
				_player._trigger_time_slow()
		"swap":
			if _player.has_method("_trigger_swap"):
				_player._trigger_swap()
	
	_play_click_feedback()

func _play_click_feedback():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.8, 0.05)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)
	
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(30)

func update_layout():
	_refresh_acquired_list()
	_build_active_buttons()
