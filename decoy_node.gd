## 替身假人：吸引障碍物的诱饵，存在期间玩家无敌
extends Area2D

const LIFETIME = 3.0
const ATTRACT_RADIUS = 300.0
const ATTRACT_FORCE = 400.0

var lifetime_timer: float = LIFETIME

@onready var sprite = $Sprite2D

func _ready():
	if sprite:
		sprite.texture = TextureGenerator.create_decoy_texture(64)
	
	add_to_group("decoys")
	body_entered.connect(_on_body_entered)
	
	modulate = Color(0.6, 0.8, 1.0, 0.7)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.6, 0.8, 1.0, 0.5), 0.2)

func _process(delta):
	lifetime_timer -= delta
	
	if lifetime_timer <= 0.0:
		_fade_out()
		return
	
	var pulse = sin(lifetime_timer * 8.0) * 0.1 + 0.9
	scale = Vector2(pulse, pulse)
	
	if lifetime_timer < 1.0:
		var blink = sin(lifetime_timer * 15.0) * 0.3 + 0.5
		modulate = Color(0.6, 0.8, 1.0, blink)
	
	_attract_obstacles(delta)

func _attract_obstacles(delta):
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		if not is_instance_valid(obstacle):
			continue
		var dist = position.distance_to(obstacle.position)
		if dist < ATTRACT_RADIUS and dist > 5.0:
			var direction = (position - obstacle.position).normalized()
			var force = ATTRACT_FORCE * (1.0 - dist / ATTRACT_RADIUS)
			obstacle.position += direction * force * delta

func _on_body_entered(body):
	if body.name == "Player":
		return
	
	if body.is_in_group("obstacles"):
		_spawn_destroy_effect(body.position)
		body.queue_free()

func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _spawn_destroy_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = pos
	effect.modulate = Color(0.6, 0.8, 1.0, 1.0)
	effect.scale = Vector2(1.5, 1.5)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(effect, "scale", Vector2(2.5, 2.5), 0.3)
	tween.tween_callback(effect.queue_free)
