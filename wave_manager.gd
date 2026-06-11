## 波浪阵管理器：控制障碍物按波浪节奏出现
extends Node

var spawner: Node2D
var wave_pattern = [0, 1, 2, 1]
var wave_index: int = 0
var is_active: bool = false
var wave_timer: float = 0.0
var wave_interval: float = 0.6
var waves_per_cycle: int = 4
var current_wave: int = 0
var cycle_complete_callback: Callable

signal wave_started(lane_index: int)
signal wave_ended
signal cycle_completed

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not is_active:
		return
	
	wave_timer += delta
	if wave_timer >= wave_interval:
		_spawn_wave_obstacle()
		wave_timer = 0.0
		current_wave += 1
		
		if current_wave >= waves_per_cycle:
			_end_wave_cycle()

func start_waves(target_spawner: Node2D) -> void:
	spawner = target_spawner
	is_active = true
	wave_index = 0
	current_wave = 0
	wave_timer = 0.0
	
	if spawner and spawner.has_method("enable_wave_mode"):
		spawner.enable_wave_mode()

func stop_waves() -> void:
	is_active = false
	
	if spawner and spawner.has_method("disable_wave_mode"):
		spawner.disable_wave_mode()
	
	wave_ended.emit()

func _spawn_wave_obstacle() -> void:
	var lane_index = wave_pattern[wave_index]
	wave_started.emit(lane_index)
	
	wave_index = (wave_index + 1) % wave_pattern.size()

func _end_wave_cycle() -> void:
	stop_waves()
	cycle_completed.emit()
	
	if cycle_complete_callback.is_valid():
		cycle_complete_callback.call()

func set_wave_pattern(new_pattern: Array) -> void:
	if new_pattern.size() > 0:
		wave_pattern = new_pattern
		wave_index = 0

func set_wave_interval(interval: float) -> void:
	wave_interval = max(0.3, interval)

func set_on_cycle_complete(callback: Callable) -> void:
	cycle_complete_callback = callback
