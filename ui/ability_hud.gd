## 能力HUD：显示能力激活状态的浮动提示
extends Control

var _flawless_label: Label = null
var _player: Node2D = null

@onready var container: VBoxContainer = $VBoxContainer

func _ready():
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	visible = false
	
	AbilityManager.ability_added.connect(_on_ability_added)
	AbilityManager.ability_stack_changed.connect(_on_ability_changed)
	
	if container:
		for child in container.get_children():
			child.queue_free()

func _process(delta):
	if _flawless_label and is_instance_valid(_flawless_label):
		if not _player or not is_instance_valid(_player):
			_player = get_tree().current_scene.get_node_or_null("Player")
		if _player and _player.has_method("get_flawless_time"):
			var current_time = _player.get_flawless_time()
			var remaining = max(0.0, 8.0 - current_time)
			if current_time < 8.0:
				_flawless_label.text = "无伤挑战: %.1fs" % remaining
				_flawless_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
			else:
				_flawless_label.text = "无伤挑战: 激活! x2.5"
				_flawless_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

func _on_ability_added(ability: AbilityData, stacks: int):
	_display_ability(ability, stacks)

func _on_ability_changed(ability_id: String, stacks: int):
	var ability = AbilityManager.get_ability_resource(ability_id)
	if not ability:
		return
	
	if stacks <= 0:
		_remove_ability_display(ability_id)
	else:
		_display_ability(ability, stacks)

func _display_ability(ability: AbilityData, stacks: int):
	if not container:
		return
	
	_remove_ability_display(ability.ability_id)
	
	if ability.ability_id == "flawless_challenge":
		_flawless_label = Label.new()
		_flawless_label.name = ability.ability_id
		_flawless_label.text = "无伤挑战: 8.0s"
		_flawless_label.add_theme_font_size_override("font_size", 16)
		_flawless_label.add_theme_color_override("font_color", _get_rarity_color(ability.rarity))
		container.add_child(_flawless_label)
		
		var tween = create_tween()
		_flawless_label.modulate = Color(1, 1, 1, 0)
		_flawless_label.scale = Vector2(0.5, 0.5)
		tween.parallel().tween_property(_flawless_label, "modulate", Color(1, 1, 1, 1), 0.3)
		tween.parallel().tween_property(_flawless_label, "scale", Vector2(1, 1), 0.3)
		return
	
	var label = Label.new()
	label.name = ability.ability_id
	label.text = _get_display_text(ability, stacks)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", _get_rarity_color(ability.rarity))
	container.add_child(label)
	
	var tween = create_tween()
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(0.5, 0.5)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(label, "scale", Vector2(1, 1), 0.3)

func _remove_ability_display(ability_id: String):
	if not container:
		return
	var existing = container.get_node_or_null(ability_id)
	if existing:
		existing.queue_free()

func _get_display_text(ability: AbilityData, stacks: int) -> String:
	var text = ability.display_name
	if ability.stackable and ability.max_stacks > 1:
		text += " x" + str(stacks)
	return text

func _get_rarity_color(rarity: AbilityData.Rarity) -> Color:
	match rarity:
		AbilityData.Rarity.COMMON:
			return Color(0.8, 0.8, 0.8)
		AbilityData.Rarity.RARE:
			return Color(0.4, 0.7, 1.0)
		AbilityData.Rarity.EPIC:
			return Color(0.8, 0.4, 1.0)
		AbilityData.Rarity.LEGENDARY:
			return Color(1.0, 0.85, 0.3)
	return Color(0.8, 0.8, 0.8)