## 障碍物概率管理器：统一管理所有障碍物类型的出现概率
class_name ObstacleProbability
extends Node

enum ObstacleType { NORMAL, ENERGY_CORE, BIG_BLOCK }

var type_weights: Array = [
	[ObstacleType.NORMAL, 58],
	[ObstacleType.ENERGY_CORE, 35],
	[ObstacleType.BIG_BLOCK, 7]
]

var total_weight: float = 100.0

var big_block_cooldown: float = 0.0
var big_block_cooldown_time: float = 2.5
var last_spawn_type: int = ObstacleType.NORMAL
var same_type_counter: int = 0
var max_same_type: int = 3

func _ready() -> void:
	_calculate_total_weight()

func _process(delta: float) -> void:
	if big_block_cooldown > 0:
		big_block_cooldown -= delta

func set_probability(type: int, weight: float) -> void:
	for i in range(type_weights.size()):
		if type_weights[i][0] == type:
			type_weights[i][1] = clamp(weight, 0, 100)
			break
	_calculate_total_weight()

func get_obstacle_type() -> int:
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for entry in type_weights:
		var type = entry[0]
		var weight = entry[1]
		cumulative += weight
		if roll < cumulative:
			if _can_spawn_type(type):
				return type
			else:
				return ObstacleType.NORMAL
	
	return ObstacleType.NORMAL

func _can_spawn_type(type: int) -> bool:
	if type == ObstacleType.BIG_BLOCK and big_block_cooldown > 0:
		return false
	
	if type == last_spawn_type:
		same_type_counter += 1
		if same_type_counter >= max_same_type:
			same_type_counter = 0
			last_spawn_type = type
			return false
	else:
		same_type_counter = 1
		last_spawn_type = type
	
	if type == ObstacleType.BIG_BLOCK:
		big_block_cooldown = big_block_cooldown_time
	
	return true

func get_probability_percentage(type: int) -> float:
	for entry in type_weights:
		if entry[0] == type:
			return (entry[1] / total_weight) * 100.0
	return 0.0

func is_energy_core() -> bool:
	return get_obstacle_type() == ObstacleType.ENERGY_CORE

func is_big_block() -> bool:
	return get_obstacle_type() == ObstacleType.BIG_BLOCK

func _calculate_total_weight() -> void:
	total_weight = 0.0
	for entry in type_weights:
		total_weight += entry[1]

func reset_to_defaults() -> void:
	type_weights = [
		[ObstacleType.NORMAL, 58],
		[ObstacleType.ENERGY_CORE, 35],
		[ObstacleType.BIG_BLOCK, 7]
	]
	_calculate_total_weight()

func debug_print_probabilities() -> void:
	print("=== 当前障碍物概率分布 ===")
	for entry in type_weights:
		var type = entry[0]
		var weight = entry[1]
		var percent = (weight / total_weight) * 100.0
		var type_name = ""
		match type:
			ObstacleType.NORMAL:
				type_name = "普通"
			ObstacleType.ENERGY_CORE:
				type_name = "能量核心"
			ObstacleType.BIG_BLOCK:
				type_name = "大块头"
		print("  %s: %.1f%% (权重:%.0f)" % [type_name, percent, weight])
	print("  总计: %.0f" % total_weight)
	print("  大块头冷却: %.1fs" % big_block_cooldown)
