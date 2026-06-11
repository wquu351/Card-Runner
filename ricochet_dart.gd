## 弹射飞镖：在障碍物间弹射的投射物，自动追踪前方目标
extends Area2D

var direction: Vector2 = Vector2.UP
var speed: float = 800.0
var max_bounces: int = 3
var current_bounces: int = 0
var bounce_range: float = 200.0
var lifetime: float = 3.0
var lifetime_timer: float = 0.0
var screen_height: float = 1170.0
var screen_width: float = 540.0
var homing_enabled: bool = false
var homing_target: Node2D = null
var homing_speed: float = 5.0

@onready var sprite = $Sprite2D

func _ready():
	var viewport = get_viewport()
	if viewport:
		screen_height = viewport.get_visible_rect().size.y
		screen_width = viewport.get_visible_rect().size.x
	
	if sprite:
		sprite.texture = TextureGenerator.create_dart_texture(32)
	
	area_entered.connect(_on_area_entered)
	
	lifetime_timer = lifetime

func _process(delta):
	if homing_enabled:
		if homing_target and is_instance_valid(homing_target):
			var target_dir = (homing_target.global_position - global_position).normalized()
			direction = direction.lerp(target_dir, homing_speed * delta).normalized()
		else:
			homing_target = _find_nearest_obstacle()
	
	position += direction * speed * delta
	
	if direction != Vector2.ZERO:
		rotation = direction.angle() + PI / 2.0
	
	lifetime_timer -= delta
	if lifetime_timer <= 0.0:
		queue_free()
		return
	
	if position.y < -100 or position.y > screen_height + 100:
		queue_free()
		return
	if position.x < -100 or position.x > screen_width + 100:
		queue_free()
		return

func _on_area_entered(area):
	if area.is_in_group("obstacles"):
		_spawn_hit_effect(area.global_position)
		
		if area.is_in_group("energy_cores"):
			area.destroy_by_skill()
			queue_free()
			return
		
		area.queue_free()
		current_bounces += 1
		
		if current_bounces <= max_bounces:
			var next_target = _find_nearest_obstacle()
			if next_target:
				direction = (next_target.position - position).normalized()
				_spawn_bounce_effect()
				return
		
		queue_free()

func _find_nearest_obstacle() -> Node2D:
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	var nearest = null
	var min_dist = bounce_range
	
	for obstacle in obstacles:
		if not is_instance_valid(obstacle):
			continue
		var to_obstacle = obstacle.position - position
		var dot = to_obstacle.normalized().dot(direction)
		if dot < 0.0:
			continue
		var dist = position.distance_to(obstacle.position)
		if dist < min_dist:
			min_dist = dist
			nearest = obstacle
	
	return nearest

func _spawn_hit_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = pos
	effect.modulate = Color(0.2, 1.0, 0.9, 1.0)
	effect.scale = Vector2(2.0, 2.0)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(effect, "scale", Vector2(3.0, 3.0), 0.3)
	tween.tween_callback(effect.queue_free)

func _spawn_bounce_effect():
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(12)
	effect.position = position
	effect.modulate = Color(0.3, 0.9, 0.8, 0.8)
	effect.scale = Vector2(1.5, 1.5)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(effect, "scale", Vector2(2.5, 2.5), 0.2)
	tween.tween_callback(effect.queue_free)
