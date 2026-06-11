## 选卡界面：展示三个随机能力供玩家选择
## 使用 CanvasLayer + PROCESS_MODE_ALWAYS 确保暂停时可用
extends CanvasLayer

signal card_selected(ability_id: String)

@onready var card_container: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/CardContainer
@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var bg_rect: ColorRect = $Background
@onready var panel: PanelContainer = $PanelContainer

var card_scene = preload("res://ui/card_selection/ability_card.tscn")
var _pending_cards: Array = []
var _cards_shown: bool = false
var _poll_timer: float = 0.0

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	
	GameFlowManager.card_selection_started.connect(_on_card_selection_started)
	GameFlowManager.card_selection_completed.connect(_on_card_selection_completed)

func _process(_delta):
	if GameFlowManager.is_selecting_card():
		_poll_timer += _delta
		if not visible or not _cards_shown:
			_force_show()
	elif not GameFlowManager.is_selecting_card() and visible:
		visible = false
		clear_cards()
		_cards_shown = false
		_pending_cards.clear()

func _force_show():
	if _pending_cards.is_empty():
		var options = GameFlowManager.get_current_card_options()
		if options.size() > 0:
			_pending_cards = options

	if _pending_cards.size() > 0 and not _cards_shown:
		show_cards(_pending_cards)
		_cards_shown = true

	visible = true
	
	## 运行时修正 Background 覆盖全屏
	if bg_rect:
		bg_rect.anchor_left = 0.0
		bg_rect.anchor_top = 0.0
		bg_rect.anchor_right = 1.0
		bg_rect.anchor_bottom = 1.0
		bg_rect.offset_left = 0.0
		bg_rect.offset_top = 0.0
		bg_rect.offset_right = 0.0
		bg_rect.offset_bottom = 0.0
		bg_rect.grow_horizontal = 2
		bg_rect.grow_vertical = 2
		bg_rect.visible = true
	
	## 运行时修正 Panel 居中
	if panel:
		panel.anchor_left = 0.5
		panel.anchor_top = 0.5
		panel.anchor_right = 0.5
		panel.anchor_bottom = 0.5
		panel.offset_left = -230.0
		panel.offset_top = -200.0
		panel.offset_right = 230.0
		panel.offset_bottom = 200.0
		panel.grow_horizontal = 2
		panel.grow_vertical = 2
		panel.visible = true
	
	if card_container:
		card_container.visible = true
	
	## 强制刷新布局
	if panel:
		panel.reset_size()
	
	push_warning("CardSelectionUI: 通过轮询兜底强制显示 (poll_timer=%.2f)" % _poll_timer)

func _on_card_selection_started(cards: Array):
	_pending_cards = cards
	_cards_shown = false
	_poll_timer = 0.0

	show_cards(cards)
	_cards_shown = true
	visible = true

	if bg_rect:
		bg_rect.visible = true
	if panel:
		panel.visible = true

func force_show_from_trigger(cards: Array):
	_pending_cards = cards
	_cards_shown = false
	_poll_timer = 0.0

	show_cards(cards)
	_cards_shown = true
	visible = true

	if bg_rect:
		bg_rect.visible = true
	if panel:
		panel.visible = true

func _on_card_selection_completed(_ability: AbilityData):
	visible = false
	clear_cards()
	_pending_cards.clear()
	
	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager:
		game_manager.update_score_display()
		game_manager.update_lives_display()

func show_cards(cards: Array[AbilityData]):
	clear_cards()
	
	if title_label:
		title_label.text = "选择一项能力"
	
	var sorted_cards = _sort_cards_by_rarity(cards)
	
	for card_data in sorted_cards:
		var card = card_scene.instantiate()
		card_container.add_child(card)
		card.setup(card_data)
		card.card_clicked.connect(_on_card_clicked)

func _sort_cards_by_rarity(cards: Array[AbilityData]) -> Array[AbilityData]:
	var sorted: Array[AbilityData] = []
	var legendary_cards: Array[AbilityData] = []
	var epic_cards: Array[AbilityData] = []
	var rare_cards: Array[AbilityData] = []
	var common_cards: Array[AbilityData] = []
	
	for card in cards:
		match card.rarity:
			AbilityData.Rarity.LEGENDARY:
				legendary_cards.append(card)
			AbilityData.Rarity.EPIC:
				epic_cards.append(card)
			AbilityData.Rarity.RARE:
				rare_cards.append(card)
			AbilityData.Rarity.COMMON:
				common_cards.append(card)
	
	if legendary_cards.size() > 0:
		if legendary_cards.size() == 1:
			if cards.size() >= 3:
				sorted.append_array(common_cards)
				sorted.append_array(rare_cards)
				sorted.append_array(epic_cards)
				sorted.append(legendary_cards[0])
				if sorted.size() > 3:
					sorted = sorted.slice(0, 3)
			else:
				sorted.append(legendary_cards[0])
		else:
			sorted.append_array(legendary_cards)
	else:
		sorted.append_array(epic_cards)
		sorted.append_array(rare_cards)
		sorted.append_array(common_cards)
	
	if sorted.size() > 3:
		sorted = sorted.slice(0, 3)
	
	if sorted.size() < cards.size():
		var remaining = cards.duplicate()
		for card in sorted:
			remaining.erase(card)
		for card in remaining:
			if sorted.size() < 3:
				sorted.append(card)
	
	if legendary_cards.size() == 1 and sorted.size() == 3:
		var legendary_index = sorted.find(legendary_cards[0])
		if legendary_index != 1:
			var temp = sorted[1]
			sorted[1] = legendary_cards[0]
			sorted[legendary_index] = temp
	
	return sorted

func clear_cards():
	for child in card_container.get_children():
		child.queue_free()

func _on_card_clicked(ability_id: String):
	GameFlowManager.complete_card_selection(ability_id)
