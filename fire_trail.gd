## 火焰轨迹：玩家移动时留下的火焰尾迹
extends Area2D

const LIFETIME = 1.5

var lifetime_timer: float = LIFETIME

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	if sprite:
		sprite.texture = TextureGenerator.create_fire_texture(40, 50)
	
	area_entered.connect(_on_area_entered)

func _process(delta):
	lifetime_timer -= delta
	
	if lifetime_timer <= 0.0:
		queue_free()
		return
	
	var fade_ratio = lifetime_timer / LIFETIME
	modulate = Color(1, 1, 1, fade_ratio)
	
	var flicker = sin(lifetime_timer * 12.0) * 0.15 + 0.85
	scale = Vector2(flicker, flicker)

func _on_area_entered(area):
	if area.is_in_group("obstacles"):
		_spawn_burn_effect(area.position)
		area.queue_free()

func _spawn_burn_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(20)
	effect.position = pos
	effect.modulate = Color(1.0, 0.5, 0.1, 1.0)
	effect.scale = Vector2(2.0, 2.0)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(effect, "scale", Vector2(3.0, 3.0), 0.4)
	tween.tween_callback(effect.queue_free)
