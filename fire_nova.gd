## 火焰新星：从玩家位置向外扩散的冲击波，摧毁范围内障碍物
extends Area2D

var expand_duration: float = 0.8
var max_radius: float = 200.0
var expand_timer: float = 0.0
var expanded: bool = false
var destroyed_obstacles: Array = []

@onready var sprite = $Sprite2D
@onready var collision_shape_node = $CollisionShape2D

func _ready():
	expand_timer = expand_duration
	
	if sprite:
		sprite.texture = TextureGenerator.create_fire_texture(128, 128)
		sprite.modulate = Color(1.0, 0.5, 0.1, 0.9)
		sprite.scale = Vector2(0.1, 0.1)
	
	if collision_shape_node:
		var circle = CircleShape2D.new()
		circle.radius = 1.0
		collision_shape_node.shape = circle
	
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1

func _process(delta):
	if expanded:
		return
	
	expand_timer -= delta
	var progress = 1.0 - (expand_timer / expand_duration)
	progress = clamp(progress, 0.0, 1.0)
	
	var current_radius = max_radius * ease_out_cubic(progress)
	
	if sprite:
		var scale_val = current_radius / 64.0
		sprite.scale = Vector2(scale_val, scale_val)
		var alpha = 0.9 * (1.0 - progress * 0.8)
		sprite.modulate = Color(1.0, 0.5 + 0.3 * (1.0 - progress), 0.1, alpha)
	
	if collision_shape_node and collision_shape_node.shape:
		collision_shape_node.shape.radius = current_radius
	
	if progress > 0.05:
		var obstacles = get_tree().get_nodes_in_group("obstacles")
		for obstacle in obstacles:
			if not is_instance_valid(obstacle):
				continue
			if destroyed_obstacles.has(obstacle):
				continue
			var dist = global_position.distance_to(obstacle.global_position)
			if dist <= current_radius:
				destroyed_obstacles.append(obstacle)
				
				if obstacle.is_in_group("energy_cores"):
					obstacle.destroy_by_skill()
				else:
					obstacle.queue_free()
	
	if expand_timer <= 0.0:
		expanded = true
		queue_free()

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)
