## 能力卡片：选卡界面中的单张能力卡片按钮
extends Button

signal card_clicked(ability_id: String)

var ability_data: AbilityData
var _rarity_animation_tween: Tween

@onready var background_rect: ColorRect = $BackgroundRect
@onready var icon_rect: TextureRect = $VBoxContainer/IconRect
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel
@onready var rarity_label: Label = $VBoxContainer/InfoRow/RarityLabel
@onready var stacks_label: Label = $VBoxContainer/InfoRow/StacksLabel

func _ready():
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(data: AbilityData):
	ability_data = data
	
	if name_label:
		name_label.text = data.display_name
	
	if desc_label:
		desc_label.text = data.description
	
	if icon_rect:
		if data.icon:
			icon_rect.texture = data.icon
		else:
			icon_rect.texture = _generate_default_icon(data.rarity)
	
	if rarity_label:
		rarity_label.text = _get_rarity_text(data.rarity)
		rarity_label.add_theme_color_override("font_color", _get_rarity_color(data.rarity))
		rarity_label.add_theme_font_size_override("font_size", 11)

	if stacks_label:
		if data.stackable:
			stacks_label.text = "可叠加 (最大%d层)" % data.max_stacks
		else:
			stacks_label.text = "不可叠加"

	_set_rarity_border(data.rarity)
	_set_background_color(data.rarity)
	_start_rarity_animation(data.rarity)

func _generate_default_icon(rarity: AbilityData.Rarity) -> ImageTexture:
	var icon_size = 48
	var image = Image.create(icon_size, icon_size, false, Image.FORMAT_RGBA8)
	var color = _get_rarity_color(rarity)
	
	var center = Vector2(icon_size / 2.0, icon_size / 2.0)
	var radius = icon_size / 2.0 - 4
	
	for x in range(icon_size):
		for y in range(icon_size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha = 1.0 - (dist / radius) * 0.3
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)

func _get_rarity_text(rarity: AbilityData.Rarity) -> String:
	match rarity:
		AbilityData.Rarity.COMMON:
			return "普通"
		AbilityData.Rarity.RARE:
			return "稀有"
		AbilityData.Rarity.EPIC:
			return "史诗"
		AbilityData.Rarity.LEGENDARY:
			return "传说"
	return "普通"

func _get_rarity_color(rarity: AbilityData.Rarity) -> Color:
	match rarity:
		AbilityData.Rarity.COMMON:
			return Color(1.0, 1.0, 1.0)
		AbilityData.Rarity.RARE:
			return Color(0.3, 0.6, 1.0)
		AbilityData.Rarity.EPIC:
			return Color(0.7, 0.3, 1.0)
		AbilityData.Rarity.LEGENDARY:
			return Color(1.0, 0.8, 0.2)
	return Color(1.0, 1.0, 1.0)

func _set_rarity_border(rarity: AbilityData.Rarity):
	var border_color = _get_rarity_color(rarity)
	var border_width = 4
	
	if rarity == AbilityData.Rarity.LEGENDARY:
		border_width = 6
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.border_color = border_color.lightened(0.3)
	hover_style.set_border_width_all(border_width + 1)
	add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	add_theme_stylebox_override("pressed", pressed_style)

func _set_background_color(rarity: AbilityData.Rarity):
	if not background_rect:
		return
	
	match rarity:
		AbilityData.Rarity.COMMON:
			background_rect.color = Color(0.5, 0.5, 0.5, 0.3)
		AbilityData.Rarity.RARE:
			background_rect.color = Color(0.2, 0.4, 0.7, 0.3)
		AbilityData.Rarity.EPIC:
			background_rect.color = Color(0.4, 0.2, 0.6, 0.3)
		AbilityData.Rarity.LEGENDARY:
			background_rect.color = Color(0.15, 0.12, 0.08, 0.5)

func _start_rarity_animation(rarity: AbilityData.Rarity):
	if _rarity_animation_tween and _rarity_animation_tween.is_valid():
		_rarity_animation_tween.kill()
	
	match rarity:
		AbilityData.Rarity.RARE:
			_animate_rare_card()
		AbilityData.Rarity.EPIC:
			_animate_epic_card()
		AbilityData.Rarity.LEGENDARY:
			_animate_legendary_card()

func _animate_rare_card():
	_rarity_animation_tween = create_tween()
	_rarity_animation_tween.set_loops()
	_rarity_animation_tween.tween_property(self, "modulate:a", 0.5, 0.75)
	_rarity_animation_tween.tween_property(self, "modulate:a", 1.0, 0.75)

func _animate_epic_card():
	_rarity_animation_tween = create_tween()
	_rarity_animation_tween.set_loops()
	var purple = Color(0.7, 0.3, 1.0)
	var bright_purple = Color(0.9, 0.5, 1.0)
	_rarity_animation_tween.tween_property(self, "modulate", bright_purple, 1.0)
	_rarity_animation_tween.tween_property(self, "modulate", purple, 1.0)

func _animate_legendary_card():
	_rarity_animation_tween = create_tween()
	_rarity_animation_tween.set_loops()
	_rarity_animation_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.5)
	_rarity_animation_tween.parallel().tween_property(self, "modulate", Color(1.2, 1.0, 0.8), 0.5)
	_rarity_animation_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)
	_rarity_animation_tween.parallel().tween_property(self, "modulate", Color(1.0, 0.9, 0.6), 0.5)

func _on_pressed():
	if ability_data:
		card_clicked.emit(ability_data.ability_id)

func _on_mouse_entered():
	if _rarity_animation_tween and _rarity_animation_tween.is_valid():
		_rarity_animation_tween.pause()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)

func _on_mouse_exited():
	if _rarity_animation_tween and _rarity_animation_tween.is_valid():
		_rarity_animation_tween.play()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func get_ability_id() -> String:
	if ability_data:
		return ability_data.ability_id
	return ""
