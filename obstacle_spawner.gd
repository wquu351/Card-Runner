## 障碍物生成器：按难度曲线生成障碍物和金币
extends Node2D

var obstacle_scene = preload("res://obstacle.tscn")
var energy_core_scene = preload("res://energy_core.tscn")
var big_block_scene = preload("res://big_block.tscn")
var coin_scene = preload("res://coin.tscn")
var spawn_timer = 0.0
var next_spawn_time = 1.0
var coin_spawn_timer = 0.0
var next_coin_spawn_time = 2.0
var game_running = true
var screen_height = 1170.0
var screen_width = 540.0
var difficulty = 1.0

var obstacle_x_positions = [240, 360, 480]
var _base_obstacle_x_positions = [240, 360, 480]
var wave_pattern_index: int = 0
var wave_pattern = [0, 1, 2, 1]
var use_wave_mode: bool = false

var probability_manager: Node

func _ready():
	var viewport = get_viewport()
	if viewport:
		var rect = viewport.get_visible_rect().size
		screen_width = rect.x
		screen_height = rect.y
		## 根据实际屏幕宽度动态计算三轨道X坐标（与player.gd保持一致）
		var lane_spacing = screen_width / 4.0
		obstacle_x_positions = [int(lane_spacing), int(lane_spacing * 2), int(lane_spacing * 3)]
	
	probability_manager = Node.new()
	probability_manager.set_script(preload("res://obstacle_probability.gd"))
	add_child(probability_manager)
	
	randomize_spawn_time()

func _process(delta):
	if not game_running:
		return
	
	probability_manager._process(delta)
	
	difficulty += delta * 0.05
	
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:
		if not _is_time_slow_active():
			spawn_obstacle()
		spawn_timer = 0.0
		randomize_spawn_time()
	
	coin_spawn_timer += delta
	if coin_spawn_timer >= next_coin_spawn_time:
		spawn_coin()
		coin_spawn_timer = 0.0
		next_coin_spawn_time = randf_range(1.5, 3.0)

func randomize_spawn_time():
	next_spawn_time = randf_range(0.8, 1.5) / difficulty

func spawn_obstacle():
	var lane_index: int
	
	if use_wave_mode:
		lane_index = wave_pattern[wave_pattern_index]
		wave_pattern_index = (wave_pattern_index + 1) % wave_pattern.size()
	else:
		lane_index = randi() % obstacle_x_positions.size()
	
	var obstacle_type = probability_manager.get_obstacle_type()
	
	match obstacle_type:
		ObstacleProbability.ObstacleType.ENERGY_CORE:
			_spawn_energy_core(lane_index)
		ObstacleProbability.ObstacleType.BIG_BLOCK:
			_spawn_big_block(lane_index)
		_:
			_spawn_normal_obstacle(lane_index)

func _spawn_normal_obstacle(lane_index: int) -> void:
	var obstacle = obstacle_scene.instantiate()
	obstacle.position = Vector2(obstacle_x_positions[lane_index], -50)
	obstacle.set_meta("speed_multiplier", 1.0 + (difficulty - 1.0) * 0.3)
	
	if _should_spawn_elite():
		obstacle.set_meta("is_elite", true)
	
	add_child(obstacle)

const ELITE_MIN_DIFFICULTY: float = 4.0

func _should_spawn_elite() -> bool:
	if difficulty < ELITE_MIN_DIFFICULTY:
		return false
	
	var base_chance: float
	if difficulty < 5.0:
		base_chance = 0.05
	elif difficulty < 6.0:
		base_chance = 0.08
	elif difficulty < 7.0:
		base_chance = 0.12
	else:
		base_chance = 0.15
	
	return randf() < base_chance

func _spawn_energy_core(lane_index: int) -> void:
	var core = energy_core_scene.instantiate()
	core.position = Vector2(obstacle_x_positions[lane_index], -50)
	core.set_meta("speed_multiplier", 1.0 + (difficulty - 1.0) * 0.3)
	core.set_meta("lane_index", lane_index)
	add_child(core)

func _spawn_big_block(lane_index: int) -> void:
	if lane_index > 1:
		lane_index = 1
	
	var block = big_block_scene.instantiate()
	block.position = Vector2((obstacle_x_positions[lane_index] + obstacle_x_positions[lane_index + 1]) / 2.0, -50)
	block.set_meta("speed_multiplier", 1.0 + (difficulty - 1.0) * 0.3)
	block.set_meta("start_lane", lane_index)
	add_child(block)

func spawn_coin():
	var coin = coin_scene.instantiate()
	var x_pos = randf_range(50, screen_width - 50)
	coin.position = Vector2(x_pos, -30)
	add_child(coin)

func stop_spawning():
	game_running = false
	for child in get_children():
		if child.has_method("stop"):
			child.stop()

func reset_difficulty():
	difficulty = 1.0

func enable_wave_mode():
	use_wave_mode = true
	wave_pattern_index = 0

func disable_wave_mode():
	use_wave_mode = false

func _is_time_slow_active() -> bool:
	if AbilityManager and AbilityManager.has_meta("time_slow_active"):
		return AbilityManager.get_meta("time_slow_active")
	return false
