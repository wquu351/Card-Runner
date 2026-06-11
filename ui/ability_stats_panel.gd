## 调试面板：左侧显示所有卡牌及获取次数（Debug用）
extends Control

var _classifier = null
var _all_abilities: Array = []

const ITEM_HEIGHT = 22

func _ready():
	z_index = 10
	
	_classifier = load("res://ui/skill_classifier.gd").new()
	add_child(_classifier)
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	if AbilityManager:
		AbilityManager.ability_added.connect(_on_ability_added)
		AbilityManager.ability_stack_changed.connect(_on_ability_changed)
	
	_load_all_abilities()
	_build_display()

func _load_all_abilities():
	_all_abilities.clear()
	if not AbilityManager:
		return
	
	var all_resources = AbilityManager.get_all_ability_resources()
	for ability_id in all_resources:
		_all_abilities.append(ability_id)

func _on_ability_added(ability: AbilityData, stacks: int):
	call_deferred("_build_display")

func _on_ability_changed(ability_id: String, new_stacks: int):
	call_deferred("_build_display")

func _build_display():
	pass

func update_layout():
	_load_all_abilities()
	_build_display()
