## 障碍物：从上方落下的危险物体，与玩家碰撞造成伤害
extends Area2D

const BASE_SPEED = 400.0
var game_running = true
var screen_height = 1170.0
var rotation_speed = 0.0
var speed_multiplier = 1.0
var reflected: bool = false
var reflected_speed: float = 600.0
var has_damaged_player: bool = false
var dodged_checked: bool = false
var freeze_timer: float = 0.0
var frozen: bool = false
var slow_timer: float = 0.0
var slow_factor: float = 1.0
var time_slow_factor: float = 1.0

var is_elite: bool = false

var _player_ref: Node2D = null

@onready var sprite = $Sprite2D

func _ready():
	var viewport = get_viewport()
	if viewport:
		screen_height = viewport.get_visible_rect().size.y
	
	add_to_group("obstacles")
	
	if has_meta("speed_multiplier"):
		speed_multiplier = get_meta("speed_multiplier")
	
	if has_meta("is_elite"):
		is_elite = true
	
	if sprite:
		if is_elite:
			sprite.texture = TextureGenerator.create_obstacle_texture(28, 100)
			sprite.modulate = Color(1.0, 0.35, 0.05)
			var col_shape = $CollisionShape2D
			if col_shape and col_shape.shape is RectangleShape2D:
				col_shape.shape.size = Vector2(28, 100)
		else:
			sprite.texture = TextureGenerator.create_obstacle_texture(50, 60)
			sprite.modulate = _get_random_obstacle_color()
	
	rotation_speed = randf_range(-3.0, 3.0)

func _get_random_obstacle_color() -> Color:
	var colors = [
		Color(0.9, 0.3, 0.3),
		Color(0.3, 0.6, 0.9),
		Color(0.9, 0.7, 0.2),
		Color(0.7, 0.3, 0.9),
		Color(0.3, 0.9, 0.5),
		Color(0.9, 0.5, 0.7),
		Color(0.4, 0.8, 0.9),
		Color(0.8, 0.9, 0.3),
	]
	return colors[randi() % colors.size()]

func _process(delta):
	if not game_running:
		return
	
	if frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			frozen = false
		return
	
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0
	
	var ability_speed_mult = AbilityManager.get_attribute_value("obstacle_speed", 1.0)
	
	if reflected:
		position.y -= reflected_speed * delta
		rotation += rotation_speed * 2.0 * delta
		
		if position.y < -100:
			queue_free()
		return
	
	var decoys = get_tree().get_nodes_in_group("decoys")
	var nearest_decoy = _find_nearest_decoy(decoys)
	
	if nearest_decoy:
		var direction_x = nearest_decoy.position.x - position.x
		var homing_speed = 100.0
		position.x += sign(direction_x) * min(abs(direction_x), homing_speed * delta)
	
	position.y += BASE_SPEED * speed_multiplier * ability_speed_mult * slow_factor * time_slow_factor * delta
	rotation += rotation_speed * delta
	
	_check_perfect_dodge()
	
	if position.y > screen_height + 100:
		queue_free()

func reflect():
	reflected = true
	remove_from_group("obstacles")
	add_to_group("reflected_obstacles")
	
	if sprite:
		sprite.modulate = Color(0.5, 0.8, 1.0, 0.9)
	
	rotation_speed = randf_range(-6.0, 6.0)

func _find_nearest_decoy(decoys):
	var nearest = null
	var min_dist = 300.0
	
	for decoy in decoys:
		if not is_instance_valid(decoy):
			continue
		var dist = position.distance_to(decoy.position)
		if dist < min_dist:
			min_dist = dist
			nearest = decoy
	
	return nearest

func _on_body_entered(body):
	if reflected:
		if body.is_in_group("obstacles"):
			body.queue_free()
			_spawn_destroy_effect(body.global_position)
		return
	
	if not body.name == "Player":
		return
	
	if not body.has_method("take_hit"):
		return
	
	if is_elite and body.has_method("set_elite_hit"):
		body.set_elite_hit(true)
	
	var is_dead = body.take_hit()
	
	if is_elite and body.has_method("set_elite_hit"):
		body.set_elite_hit(false)
	
	has_damaged_player = true
	
	if is_dead:
		var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
		if game_manager:
			game_manager.game_over()
	else:
		queue_free()

func _spawn_destroy_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = pos
	effect.modulate = Color(0.5, 0.8, 1.0, 1.0)
	effect.scale = Vector2(1.5, 1.5)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(effect, "scale", Vector2(2.5, 2.5), 0.3)
	tween.tween_callback(effect.queue_free)

func stop():
	game_running = false

func freeze(duration: float):
	frozen = true
	freeze_timer = duration

func slow_down(factor: float, duration: float):
	slow_factor = factor
	slow_timer = duration

func apply_time_slow(factor: float, duration: float):
	time_slow_factor = factor
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if is_instance_valid(self):
			time_slow_factor = 1.0
	)

func _check_perfect_dodge():
	if dodged_checked or has_damaged_player or reflected:
		return
	
	if not _player_ref:
		_player_ref = get_tree().current_scene.get_node_or_null("Player")
	if not _player_ref or not is_instance_valid(_player_ref):
		return
	
	if position.y < _player_ref.position.y:
		return
	
	var horizontal_distance = abs(position.x - _player_ref.position.x)
	
	if horizontal_distance < 30.0:
		dodged_checked = true