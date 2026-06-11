## 卫星：围绕玩家旋转的轨道物体，碰撞时摧毁障碍物
extends Node2D

var orbit_radius: float = 60.0
var orbit_speed: float = 3.0
var satellite_size: float = 20.0

var _pivot: Node2D
var _satellite_area: Area2D
var _satellite_sprite: Sprite2D
var _satellite_collision: CollisionShape2D

func _ready():
	_pivot = Node2D.new()
	add_child(_pivot)
	
	_satellite_area = Area2D.new()
	_satellite_area.collision_layer = 1
	_satellite_area.collision_mask = 1
	_pivot.add_child(_satellite_area)
	_satellite_area.position = Vector2(orbit_radius, 0)
	
	_satellite_sprite = Sprite2D.new()
	_satellite_sprite.texture = _create_satellite_texture()
	_satellite_area.add_child(_satellite_sprite)
	
	var shape = CircleShape2D.new()
	shape.radius = satellite_size / 2.0
	_satellite_collision = CollisionShape2D.new()
	_satellite_collision.shape = shape
	_satellite_area.add_child(_satellite_collision)
	
	_satellite_area.area_entered.connect(_on_area_entered)
	_satellite_area.body_entered.connect(_on_body_entered)

func _process(delta):
	_pivot.rotation += orbit_speed * delta
	
	var pulse = sin(Time.get_ticks_msec() / 150.0) * 0.2 + 0.8
	_satellite_sprite.modulate = Color(0.3, 0.7, 1.0, pulse)

func _on_area_entered(area):
	if area.is_in_group("obstacles"):
		_destroy_obstacle(area)

func _on_body_entered(body):
	if body.is_in_group("obstacles"):
		_destroy_obstacle(body)

func _destroy_obstacle(obstacle):
	_spawn_destroy_effect(obstacle.global_position)
	
	if obstacle.is_in_group("energy_cores"):
		obstacle.destroy_by_skill()
	else:
		obstacle.queue_free()

func _spawn_destroy_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = pos
	effect.modulate = Color(0.3, 0.7, 1.0, 1.0)
	effect.scale = Vector2(2.0, 2.0)
	get_tree().current_scene.add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(effect, "scale", Vector2(3.5, 3.5), 0.25)
	tween.tween_callback(effect.queue_free)

func _create_satellite_texture() -> ImageTexture:
	var size = int(satellite_size)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0
	var radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - center, y - center).length()
			if dist <= radius:
				var alpha = 1.0
				if dist > radius - 2:
					alpha = (radius - dist) / 2.0
				var glow = 1.0 - (dist / radius)
				image.set_pixel(x, y, Color(0.3 + glow * 0.3, 0.6 + glow * 0.3, 1.0, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)
