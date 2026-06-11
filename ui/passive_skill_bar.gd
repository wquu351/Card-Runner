## 被动技能栏：右侧垂直排列，一体化列表设计，白色光晕，仅显示状态不可点击，按获取顺序动态排序
extends Control

var _skill_panels: Dictionary = {}
var _player: Node2D = null
var _classifier = null
var _acquired_passive_skills: Array = []

const BASE_PANEL_SIZE = Vector2(165, 40)
var PANEL_SIZE = Vector2(165, 40)
const GLOW_WIDTH = 3
const PANEL_SPACING = 0

func _ready():
	z_index = 10
	
	_classifier = load("res://ui/skill_classifier.gd").new()
	add_child(_classifier)
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	if AbilityManager:
		AbilityManager.ability_added.connect(_on_ability_added)
		AbilityManager.ability_stack_changed.connect(_on_ability_changed)
	
	_refresh_acquired_list()
	_build_passive_panels()

func _on_ability_added(ability, stacks):
	if ability and _classifier.is_passive_skill(ability.ability_id):
		if not _acquired_passive_skills.has(ability.ability_id):
			_acquired_passive_skills.append(ability.ability_id)
			call_deferred("_build_passive_panels")

func _on_ability_changed(ability_id: String, new_stacks: int):
	if new_stacks <= 0 and _acquired_passive_skills.has(ability_id):
		_acquired_passive_skills.erase(ability_id)
		call_deferred("_build_passive_panels")
	elif new_stacks > 0 and not _acquired_passive_skills.has(ability_id):
		if _classifier.is_passive_skill(ability_id):
			_acquired_passive_skills.append(ability_id)
			call_deferred("_build_passive_panels")

func _refresh_acquired_list():
	_acquired_passive_skills.clear()
	if not AbilityManager:
		return
	
	var owned = AbilityManager.get_all_owned_abilities()
	for ability_id in owned:
		if owned[ability_id] > 0 and _classifier.is_passive_skill(ability_id):
			_acquired_passive_skills.append(ability_id)

func _build_passive_panels():
	for child in get_children():
		if child == _classifier:
			continue
		child.queue_free()
	_skill_panels.clear()
	
	## 根据父容器宽度自适应缩放面板尺寸
	var parent_size = size if size.x > 0 else Vector2(165, 40)
	if parent_size.x > 0:
		var scale_factor = clampf(parent_size.x / 165.0, 0.7, 1.0)
		PANEL_SIZE = Vector2(int(BASE_PANEL_SIZE.x * scale_factor), int(BASE_PANEL_SIZE.y * scale_factor))
	else:
		PANEL_SIZE = BASE_PANEL_SIZE
	
	var passive_skills = _acquired_passive_skills.duplicate()
	
	if passive_skills.size() == 0:
		visible = false
		return
	
	visible = true
	
	var container_style = StyleBoxFlat.new()
	container_style.bg_color = Color(0.10, 0.10, 0.15, 0.92)
	container_style.border_color = Color(0.4, 0.5, 0.7, 0.6)
	container_style.set_border_width_all(GLOW_WIDTH)
	container_style.set_corner_radius_all(12)
	container_style.shadow_color = Color(0.2, 0.3, 0.6, 0.25)
	container_style.set_shadow_size(8)
	container_style.set_shadow_offset(Vector2(0, 3))
	add_theme_stylebox_override("panel", container_style)
	
	var valid_passive_skills = []
	for skill_id in passive_skills:
		if not _classifier.get_skill_definition(skill_id).is_empty():
			valid_passive_skills.append(skill_id)
	
	var total_content_height = valid_passive_skills.size() * PANEL_SIZE.y + (valid_passive_skills.size() - 1) * PANEL_SPACING
	var container_width = PANEL_SIZE.x + GLOW_WIDTH * 2
	var container_height = total_content_height + GLOW_WIDTH * 2
	
	custom_minimum_size = Vector2(container_width, container_height)
	size = Vector2(container_width, container_height)
	
	var current_y = float(GLOW_WIDTH)

	for i in range(passive_skills.size()):
		var skill_id = passive_skills[i]
		var def = _classifier.get_skill_definition(skill_id)
		if def.is_empty():
			continue
		
		var is_first = (_skill_panels.size() == 0)
		var is_last = (i == passive_skills.size() - 1)
		
		var panel_y = current_y
		
		var panel = Panel.new()
		panel.name = "Passive_" + skill_id
		panel.anchor_left = 0.0
		panel.anchor_top = 0.0
		panel.anchor_right = 0.0
		panel.anchor_bottom = 0.0
		panel.custom_minimum_size = Vector2(PANEL_SIZE.x, PANEL_SIZE.y)
		panel.position = Vector2(GLOW_WIDTH, panel_y)
		panel.size = Vector2(PANEL_SIZE.x, PANEL_SIZE.y)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.clip_contents = true
		panel.z_index = 5
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.13, 0.13, 0.19, 0.7)
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		
		style.corner_radius_top_left = 8 if is_first else 0
		style.corner_radius_top_right = 8 if is_first else 0
		style.corner_radius_bottom_left = 8 if is_last else 0
		style.corner_radius_bottom_right = 8 if is_last else 0
		style.shadow_size = 0
		panel.add_theme_stylebox_override("panel", style)
		
		if not is_last:
			var separator = HSeparator.new()
			separator.position = Vector2(4, PANEL_SIZE.y - 1)
			separator.size = Vector2(PANEL_SIZE.x - 8, 1)
			separator.modulate = Color(0.3, 0.35, 0.45, 0.4)
			separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(separator)
		
		var icon_label = Label.new()
		icon_label.name = "IconLabel"
		icon_label.text = def["icon_text"]
		icon_label.position = Vector2(8, 2)
		icon_label.custom_minimum_size = Vector2(24, 24)
		icon_label.size = Vector2(24, 24)
		icon_label.add_theme_font_size_override("font_size", 14)
		icon_label.add_theme_color_override("font_color", def["color"])
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.anchor_left = 0.0
		icon_label.anchor_top = 0.0
		icon_label.anchor_right = 0.0
		icon_label.anchor_bottom = 0.0
		panel.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = def["display_name"].left(5)
		name_label.position = Vector2(36, 3)
		name_label.custom_minimum_size = Vector2(80, 18)
		name_label.size = Vector2(80, 18)
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1.0))
		name_label.anchor_left = 0.0
		name_label.anchor_top = 0.0
		name_label.anchor_right = 0.0
		name_label.anchor_bottom = 0.0
		panel.add_child(name_label)
		
		var status_label = Label.new()
		status_label.name = "StatusLabel"
		status_label.text = "自动"
		status_label.position = Vector2(123, 5)
		status_label.custom_minimum_size = Vector2(32, 16)
		status_label.size = Vector2(32, 16)
		status_label.add_theme_font_size_override("font_size", 8)
		status_label.add_theme_color_override("font_color", Color(0.65, 0.70, 0.78, 0.85))
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status_label.anchor_left = 0.0
		status_label.anchor_top = 0.0
		status_label.anchor_right = 0.0
		status_label.anchor_bottom = 0.0
		panel.add_child(status_label)
		
		var cooldown_bar = ProgressBar.new()
		cooldown_bar.name = "CooldownBar"
		cooldown_bar.position = Vector2(8, 26)
		cooldown_bar.custom_minimum_size = Vector2(149, 10)
		cooldown_bar.size = Vector2(149, 10)
		cooldown_bar.max_value = 1.0
		cooldown_bar.value = 0.0
		cooldown_bar.show_percentage = false
		cooldown_bar.anchor_left = 0.0
		cooldown_bar.anchor_top = 0.0
		cooldown_bar.anchor_right = 0.0
		cooldown_bar.anchor_bottom = 0.0
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = def["glow_color"]
		fill_style.bg_color.a = 0.85
		fill_style.set_corner_radius_all(2)
		cooldown_bar.add_theme_stylebox_override("fill", fill_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.06, 0.06, 0.08, 0.5)
		bg_style.set_corner_radius_all(2)
		cooldown_bar.add_theme_stylebox_override("background", bg_style)
		
		panel.add_child(cooldown_bar)
		add_child(panel)
		
		current_y += PANEL_SIZE.y + PANEL_SPACING
		
		_skill_panels[skill_id] = {
			"panel": panel,
			"icon_label": icon_label,
			"name_label": name_label,
			"status_label": status_label,
			"cooldown_bar": cooldown_bar,
			"def": def
		}

func _process(_delta):
	if not _player or not is_instance_valid(_player):
		_player = get_tree().current_scene.get_node_or_null("Player")
	if not _player:
		return
	
	for skill_id in _skill_panels:
		var data = _skill_panels[skill_id]
		var panel = data["panel"]
		var cooldown_bar = data["cooldown_bar"]
		var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
		
		var cooldown_ratio = _get_cooldown_ratio(skill_id)
		
		if style:
			if cooldown_ratio >= 1.0:
				style.bg_color = Color(0.15, 0.15, 0.22, 0.75)
				data["name_label"].add_theme_color_override("font_color", Color(0.92, 0.92, 0.97, 1.0))
			else:
				style.bg_color = Color(0.09, 0.09, 0.14, 0.60)
				data["name_label"].add_theme_color_override("font_color", Color(0.62, 0.62, 0.70, 0.80))
		
		if cooldown_bar:
			cooldown_bar.value = cooldown_ratio

func _check_owned(skill_id: String) -> bool:
	return _acquired_passive_skills.has(skill_id)

func _get_cooldown_ratio(skill_id: String) -> float:
	if not _player:
		return 1.0
	
	match skill_id:
		"ricochet_dart":
			var interval = _player.get("ricochet_dart_interval")
			var timer = _player.get("ricochet_dart_timer")
			if interval and timer != null and interval > 0:
				return clamp(1.0 - (timer / interval), 0.0, 1.0)
		"time_bomb":
			var interval = _player.get("time_bomb_interval")
			var timer = _player.get("time_bomb_timer")
			if interval and timer != null and interval > 0:
				return clamp(1.0 - (timer / interval), 0.0, 1.0)
		"auto_dodge":
			var cd_timer = _player.get("auto_dodge_cooldown_timer")
			var cd_max = _player.get("auto_dodge_cooldown")
			if cd_timer != null and cd_max and cd_max > 0:
				return clamp(1.0 - (cd_timer / cd_max), 0.0, 1.0)
		"fire_nova":
			var interval = _player.get("fire_nova_interval")
			var timer = _player.get("fire_nova_timer")
			if interval and timer != null and interval > 0:
				return clamp(1.0 - (timer / interval), 0.0, 1.0)
		"revenge_spirit":
			var cd_timer = _player.get("revenge_spirit_cooldown_timer")
			var cd_max = _player.get("revenge_spirit_cooldown")
			if cd_timer != null and cd_max and cd_max > 0:
				return clamp(1.0 - (cd_timer / cd_max), 0.0, 1.0)
		"phoenix_reborn":
			var cd_timer = _player.get("phoenix_reborn_cooldown_timer")
			var cd_max = _player.get("phoenix_reborn_cooldown")
			if cd_timer != null and cd_max and cd_max > 0:
				return clamp(1.0 - (cd_timer / cd_max), 0.0, 1.0)
		"phantom_cloak":
			var is_active = _player.get("phantom_cloak_active")
			if is_active:
				var active_timer = _player.get("phantom_cloak_active_timer")
				var duration = _player.get("phantom_cloak_duration")
				if active_timer != null and duration and duration > 0:
					return clamp(active_timer / duration, 0.0, 1.0)
			else:
				var cd_timer = _player.get("phantom_cloak_cooldown_after")
				var cd_max = _player.get("phantom_cloak_interval")
				if cd_timer != null and cd_timer > 0.0 and cd_max and cd_max > 0:
					return clamp(1.0 - (cd_timer / cd_max), 0.0, 1.0)
				var wait_timer = _player.get("phantom_cloak_timer")
				var wait_max = _player.get("phantom_cloak_interval")
				if wait_timer != null and wait_max and wait_max > 0:
					return clamp(wait_timer / wait_max, 0.0, 1.0)
		"mirror_shield":
			return 1.0
		"yoyo":
			var interval = _player.get("yoyo_attack_interval")
			var timer = _player.get("yoyo_attack_timer")
			if interval and timer != null and interval > 0:
				return clamp(1.0 - (timer / interval), 0.0, 1.0)
		"score_shield":
			var layers = _player.get("score_shield_layers")
			var max_layers = _player.get("score_shield_max_layers")
			if layers != null and max_layers and max_layers > 0:
				return clamp(float(layers) / float(max_layers), 0.0, 1.0)
	return 1.0

func update_layout():
	_refresh_acquired_list()
	_build_passive_panels()
