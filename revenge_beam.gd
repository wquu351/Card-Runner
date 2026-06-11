## 复仇光束：受到伤害后释放的追踪光束
extends Area2D

const LIFETIME = 1.0
const MOVE_SPEED = 800.0

var lifetime_timer: float = LIFETIME

@onready var sprite = $Sprite2D

func _ready():
	if sprite:
		sprite.texture = TextureGenerator.create_beam_texture(40, 400)
	
	area_entered.connect(_on_area_entered)
	
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.9), 0.1)

func _process(delta):
	lifetime_timer -= delta
	
	if lifetime_timer <= 0.0:
		queue_free()
		return
	
	position.y -= MOVE_SPEED * delta
	
	var fade_ratio = lifetime_timer / LIFETIME
	if lifetime_timer < 0.3:
		modulate = Color(1, 1, 1, fade_ratio / 0.3 * 0.9)
	
	var pulse = sin(lifetime_timer * 15.0) * 0.1 + 0.9
	scale = Vector2(pulse, 1.0)

func _on_area_entered(area):
	if area.is_in_group("obstacles"):
		_spawn_disintegrate_effect(area.position)
		area.queue_free()

func _spawn_disintegrate_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = pos
	effect.modulate = Color(0.8, 0.4, 1.0, 1.0)
	effect.scale = Vector2(1.5, 1.5)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(effect, "scale", Vector2(2.5, 2.5), 0.3)
	tween.tween_callback(effect.queue_free)
