## 能力管理器：管理能力的添加、移除、叠加和属性修正计算
extends Node

signal ability_added(ability: AbilityData, current_stacks: int)
signal ability_stack_changed(ability_id: String, new_stacks: int)
signal attribute_changed(attribute_name: String, new_value: float)
signal skill_used(skill_id: String)

var owned_abilities: Dictionary = {}
var ability_resources: Dictionary = {}
var ability_add_count: int = 0

var _multiply_modifiers: Dictionary = {}
var _add_modifiers: Dictionary = {}

func _ready():
	_load_all_abilities()

func _load_all_abilities():
	## 先尝试扫描目录（PC 上有效）
	var dir = DirAccess.open("res://abilities/data")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var ability = load("res://abilities/data/" + file_name)
				if ability and ability is AbilityData:
					ability_resources[ability.ability_id] = ability
			file_name = dir.get_next()
		dir.list_dir_end()
	
	## 如果扫描结果为空（安卓上常见），使用硬编码列表兜底
	if ability_resources.is_empty():
		print("[DBG-AM] DirAccess 扫描为空，使用硬编码列表")
		var hardcoded_ids = [
			"auto_dodge", "charged_jump", "coin_bonus", "decoy", "fast_recovery",
			"fire_nova", "flawless_challenge", "last_stand", "lucky_rabbit_foot",
			"magnet_gloves", "mirror_shield", "phantom_cloak", "phoenix_reborn",
			"revenge_spirit", "ricochet_dart", "satellite", "score_pouch",
			"score_shield", "soft_kneepads", "spare_life", "swap", "time_bomb",
			"time_slow", "wall_phase", "yoyo"
		]
		for ability_id in hardcoded_ids:
			var path = "res://abilities/data/" + ability_id + ".tres"
			var ability = load(path)
			if ability and ability is AbilityData:
				ability_resources[ability.ability_id] = ability
			else:
				push_warning("Failed to load ability: " + path)
	
	print("[DBG-AM] _load_all_abilities 完成，共加载 %d 个能力" % ability_resources.size())

func register_ability(ability: AbilityData):
	if ability_resources.has(ability.ability_id):
		return
	ability_resources[ability.ability_id] = ability

func add_ability(ability_id: String) -> bool:
	var ability = ability_resources.get(ability_id)
	if not ability:
		push_error("Ability not found: " + ability_id)
		return false
	
	var current_stacks = owned_abilities.get(ability_id, 0)
	
	if ability.stackable:
		if current_stacks >= ability.max_stacks:
			push_warning("Ability reached max stacks: " + ability_id)
			return false
	else:
		if current_stacks > 0:
			push_warning("Ability already owned and not stackable: " + ability_id)
			return false
	
	owned_abilities[ability_id] = current_stacks + 1
	
	ability_add_count += 1
	
	_apply_ability_effect(ability, 1)
	
	ability_added.emit(ability, owned_abilities[ability_id])
	ability_stack_changed.emit(ability_id, owned_abilities[ability_id])
	
	return true

func remove_ability(ability_id: String) -> bool:
	var ability = ability_resources.get(ability_id)
	if not ability:
		return false
	
	var current_stacks = owned_abilities.get(ability_id, 0)
	if current_stacks <= 0:
		return false
	
	_apply_ability_effect(ability, -1)
	
	owned_abilities[ability_id] = current_stacks - 1
	
	if owned_abilities[ability_id] <= 0:
		owned_abilities.erase(ability_id)
	
	ability_stack_changed.emit(ability_id, owned_abilities.get(ability_id, 0))
	
	return true

func _apply_ability_effect(ability: AbilityData, multiplier: int):
	if ability.effect_type == AbilityData.EffectType.TRIGGER:
		return
	
	var attr = ability.target_attribute
	if attr.is_empty():
		return
	
	match ability.effect_type:
		AbilityData.EffectType.MULTIPLY:
			if not _multiply_modifiers.has(attr):
				_multiply_modifiers[attr] = 1.0
			_multiply_modifiers[attr] *= pow(ability.effect_value, multiplier)
		
		AbilityData.EffectType.ADD:
			if not _add_modifiers.has(attr):
				_add_modifiers[attr] = 0.0
			_add_modifiers[attr] += ability.effect_value * multiplier
		
		AbilityData.EffectType.SET:
			if multiplier > 0:
				_add_modifiers[attr + "_set_override"] = ability.effect_value
	
	var final_value = get_attribute_value(attr, 0.0)
	attribute_changed.emit(attr, final_value)

func get_attribute_value(attribute_name: String, base_value: float) -> float:
	var result = base_value
	
	if _add_modifiers.has(attribute_name):
		result += _add_modifiers[attribute_name]
	
	if _multiply_modifiers.has(attribute_name):
		result *= _multiply_modifiers[attribute_name]
	
	return result

func apply_temporary_multiplier(attribute_name: String, multiplier: float):
	if not _multiply_modifiers.has(attribute_name):
		_multiply_modifiers[attribute_name] = 1.0
	_multiply_modifiers[attribute_name] *= multiplier
	attribute_changed.emit(attribute_name, get_attribute_value(attribute_name, 0.0))

func remove_temporary_multiplier(attribute_name: String, multiplier: float):
	if _multiply_modifiers.has(attribute_name):
		_multiply_modifiers[attribute_name] /= multiplier
		if _multiply_modifiers[attribute_name] == 1.0:
			_multiply_modifiers.erase(attribute_name)
		attribute_changed.emit(attribute_name, get_attribute_value(attribute_name, 0.0))

func add_persistent_add_bonus(attribute_name: String, value: float):
	if not _add_modifiers.has(attribute_name):
		_add_modifiers[attribute_name] = 0.0
	_add_modifiers[attribute_name] += value
	attribute_changed.emit(attribute_name, get_attribute_value(attribute_name, 0.0))

func get_ability_stacks(ability_id: String) -> int:
	return owned_abilities.get(ability_id, 0)

func has_ability(ability_id: String) -> bool:
	return owned_abilities.has(ability_id) and owned_abilities[ability_id] > 0

func get_all_owned_abilities() -> Dictionary:
	return owned_abilities.duplicate()

func get_ability_resource(ability_id: String) -> AbilityData:
	return ability_resources.get(ability_id)

func get_all_ability_resources() -> Dictionary:
	return ability_resources.duplicate()

func reset():
	owned_abilities.clear()
	_multiply_modifiers.clear()
	_add_modifiers.clear()
	ability_add_count = 0

func get_debug_info() -> String:
	var info = "=== Ability Manager Debug ===\n"
	info += "Owned Abilities:\n"
	for id in owned_abilities:
		var ability = ability_resources.get(id)
		if ability:
			info += "  - %s: %d stacks\n" % [ability.display_name, owned_abilities[id]]
	info += "\nMultiply Modifiers:\n"
	for attr in _multiply_modifiers:
		info += "  - %s: x%.2f\n" % [attr, _multiply_modifiers[attr]]
	info += "\nAdd Modifiers:\n"
	for attr in _add_modifiers:
		info += "  - %s: +%.2f\n" % [attr, _add_modifiers[attr]]
	return info
