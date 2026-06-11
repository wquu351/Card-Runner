## 大块头：两倍大的蓝色方块，横跨两个轨道
extends Area2D

const BASE_SPEED = 400.0
var game_running = true
var screen_height = 1170.0
var speed_multiplier = 1.0
var has_damaged_player: bool = false
var time_slow_factor: float = 1.0

@onready var sprite = $Sprite2D

func _ready():
	var viewport = get_viewport()
	if viewport:
		screen_height = viewport.get_visible_rect().size.y
	
	add_to_group("obstacles")
	
	if has_meta("speed_multiplier"):
		speed_multiplier = get_meta("speed_multiplier")
	
	_setup_visuals()

func _setup_visuals() -> void:
	if sprite:
		sprite.texture = TextureGenerator.create_big_block_texture(100, 60)
		sprite.modulate = Color(0.35, 0.55, 0.9, 1.0)

func _process(delta):
	if not game_running:
		return
	
	var ability_speed_mult = AbilityManager.get_attribute_value("obstacle_speed", 1.0)
	position.y += BASE_SPEED * speed_multiplier * ability_speed_mult * time_slow_factor * delta
	
	if position.y > screen_height + 100:
		queue_free()

func apply_time_slow(factor: float, duration: float):
	time_slow_factor = factor
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if is_instance_valid(self):
			time_slow_factor = 1.0
	)

func _on_body_entered(body):
	if not body.name == "Player":
		return
	
	if not body.has_method("take_hit"):
		return
	
	var is_dead = body.take_hit()
	has_damaged_player = true
	
	if is_dead:
		var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
		if game_manager:
			game_manager.game_over()
	else:
		queue_free()

func stop():
	game_running = false
