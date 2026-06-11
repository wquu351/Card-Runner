## 定时炸弹：延时爆炸的投射物，摧毁大范围障碍物
extends Area2D

var fuse_time: float = 2.0
var explosion_radius: float = 200.0
var fuse_timer: float = 0.0
var exploded: bool = false
var screen_height: float = 1170.0

@onready var sprite = $Sprite2D

func _ready():
	fuse_timer = fuse_time
	var viewport = get_viewport()
	if viewport:
		screen_height = viewport.get_visible_rect().size.y
	if sprite:
		sprite.texture = TextureGenerator.create_bomb_texture(48)

func _process(delta):
	if exploded:
		return
	fuse_timer -= delta
	if sprite:
		var pulse = 1.0 + sin(fuse_timer * 8.0) * 0.15 * (1.0 - fuse_timer / fuse_time)
		sprite.scale = Vector2(pulse, pulse)
		sprite.modulate = Color(1.0, 1.0 - (1.0 - fuse_timer / fuse_time) * 0.5, 1.0 - (1.0 - fuse_timer / fuse_time) * 0.8, 1.0)
	if fuse_timer <= 0.0:
		_explode()

func _explode():
	exploded = true
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	var destroyed_count = 0
	for obstacle in obstacles:
		if not is_instance_valid(obstacle):
			continue
		var dist = global_position.distance_to(obstacle.global_position)
		if dist <= explosion_radius:
			if obstacle.is_in_group("energy_cores"):
				obstacle.destroy_by_skill()
			else:
				obstacle.queue_free()
			destroyed_count += 1
	_spawn_explosion_effect()
	queue_free()

func _spawn_explosion_effect():
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(128)
	effect.position = global_position
	effect.modulate = Color(1.0, 0.6, 0.2, 0.9)
	effect.scale = Vector2(0.5, 0.5)
	get_parent().add_child(effect)
	var tween = effect.create_tween()
	tween.tween_property(effect, "scale", Vector2(6.0, 6.0), 0.3)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(effect.queue_free)

	var ring = Sprite2D.new()
	ring.texture = TextureGenerator.create_particle_texture(64)
	ring.position = global_position
	ring.modulate = Color(1.0, 0.8, 0.3, 0.7)
	ring.scale = Vector2(0.3, 0.3)
	get_parent().add_child(ring)
	var ring_tween = ring.create_tween()
	ring_tween.tween_property(ring, "scale", Vector2(8.0, 8.0), 0.35)
	ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	ring_tween.tween_callback(ring.queue_free)
