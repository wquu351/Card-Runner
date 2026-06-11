## 游戏流程管理器：控制游戏状态切换（游玩、选卡、暂停、结束）
extends Node

enum GameState {
	PLAYING,
	SELECTING_CARD,
	PAUSED,
	GAME_OVER
}

signal state_changed(new_state: GameState)
signal card_selection_started(available_cards: Array)
signal card_selection_completed(selected_ability: AbilityData)
signal pool_exhausted_bonus()

var current_state: GameState = GameState.PLAYING
var previous_state: GameState = GameState.PLAYING

var ability_pool: Array[String] = []
var current_card_options: Array[AbilityData] = []
var cards_to_show: int = 3

var _first_selection_bonus: bool = true

func _ready():
	_load_ability_pool()

func _load_ability_pool():
	var all_abilities = AbilityManager.get_all_ability_resources()
	for ability_id in all_abilities:
		ability_pool.append(ability_id)

func set_state(new_state: GameState):
	if current_state == new_state:
		return
	
	previous_state = current_state
	current_state = new_state
	
	match new_state:
		GameState.SELECTING_CARD:
			_pause_game()
		GameState.PLAYING:
			_resume_game()
		GameState.PAUSED:
			_pause_game()
		GameState.GAME_OVER:
			_pause_game()
	
	state_changed.emit(new_state)

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_selecting_card() -> bool:
	return current_state == GameState.SELECTING_CARD

func request_card_selection() -> bool:
	if current_state != GameState.PLAYING:
		push_warning("Cannot start card selection in current state")
		return false

	var am_resources = AbilityManager.get_all_ability_resources()
	if ability_pool.is_empty() and not am_resources.is_empty():
		for ability_id in am_resources:
			ability_pool.append(ability_id)

	current_card_options = _draw_random_cards(cards_to_show)

	if current_card_options.is_empty():
		push_warning("No available cards to select")
		pool_exhausted_bonus.emit()
		return false

	set_state(GameState.SELECTING_CARD)
	card_selection_started.emit(current_card_options)

	return true

func complete_card_selection(ability_id: String) -> bool:
	if current_state != GameState.SELECTING_CARD:
		push_warning("Not in card selection state")
		return false
	
	var ability = AbilityManager.get_ability_resource(ability_id)
	if not ability:
		push_error("Ability not found: " + ability_id)
		return false
	
	var success = AbilityManager.add_ability(ability_id)
	if not success:
		push_warning("Failed to add ability: " + ability_id)
		return false
	
	_first_selection_bonus = false
	
	set_state(GameState.PLAYING)
	card_selection_completed.emit(ability)
	
	current_card_options.clear()
	
	return true

func _draw_random_cards(count: int) -> Array[AbilityData]:
	var available: Array[AbilityData] = []
	
	for ability_id in ability_pool:
		var ability = AbilityManager.get_ability_resource(ability_id)
		if not ability:
			continue
		
		if not _is_ability_available(ability_id):
			continue
		
		available.append(ability)
	
	if available.is_empty():
		return []
	
	var result: Array[AbilityData] = []
	var temp_pool = available.duplicate()
	
	var draw_count = mini(count, temp_pool.size())
	
	for i in range(draw_count):
		if temp_pool.is_empty():
			break
		
		var index = _weighted_random_index(temp_pool)
		result.append(temp_pool[index])
		temp_pool.remove_at(index)
	
	return result

func _get_rarity_weight(rarity: int) -> float:
	var base_weight: float
	match rarity:
		AbilityData.Rarity.COMMON:
			base_weight = 50.0
		AbilityData.Rarity.RARE:
			base_weight = 30.0
		AbilityData.Rarity.EPIC:
			base_weight = 15.0
		AbilityData.Rarity.LEGENDARY:
			base_weight = 5.0
		_:
			base_weight = 50.0
	
	if _first_selection_bonus:
		if rarity == AbilityData.Rarity.RARE or rarity == AbilityData.Rarity.EPIC:
			base_weight *= 1.5
	
	return base_weight

func _weighted_random_index(pool: Array[AbilityData]) -> int:
	var total_weight: float = 0.0
	var weights: Array[float] = []
	
	for ability in pool:
		var w = _get_rarity_weight(ability.rarity)
		weights.append(w)
		total_weight += w
	
	var roll = randf() * total_weight
	var cumulative: float = 0.0
	
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i
	
	return pool.size() - 1

func _is_ability_available(ability_id: String) -> bool:
	var ability = AbilityManager.get_ability_resource(ability_id)
	if not ability:
		return false
	
	if not ability.stackable:
		return not AbilityManager.has_ability(ability_id)
	
	var current_stacks = AbilityManager.get_ability_stacks(ability_id)
	return current_stacks < ability.max_stacks

func _pause_game():
	get_tree().paused = true

func _resume_game():
	get_tree().paused = false

func reset():
	set_state(GameState.PLAYING)
	current_card_options.clear()
	_first_selection_bonus = true

func get_current_card_options() -> Array[AbilityData]:
	return current_card_options

func set_cards_count(count: int):
	cards_to_show = count
