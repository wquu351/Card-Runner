## 幻影残像：玩家移动时留下的短暂残影效果
extends Area2D

const LIFETIME = 0.5

var lifetime_timer: float = LIFETIME

@onready var sprite = $Sprite2D

func _ready():
	if sprite:
		sprite.texture = TextureGenerator.create_player_texture(64)
	
	add_to_group("decoys")
	add_to_group("phantom_afterimages")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	modulate = Color(0.7, 0.6, 1.0, 0.4)
	if sprite:
		sprite.modulate = modulate
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.6, 1.0, 0.25), 0.15)

func _process(delta):
	lifetime_timer -= delta
	
	var pulse = sin(lifetime_timer * 12.0) * 0.15 + 0.85
	modulate.a = max(0.05, 0.35 * pulse)
	if sprite:
		sprite.modulate = modulate
	
	scale = Vector2(pulse * 0.95, pulse * 0.95)
	
	if lifetime_timer <= 0.0:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		return
	if body.is_in_group("obstacles"):
		body.queue_free()
		_spawn_hit_effect(body.global_position)

func _on_area_entered(area):
	if area.is_in_group("obstacles"):
		area.queue_free()
		_spawn_hit_effect(area.global_position)

func _spawn_hit_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = pos
	effect.modulate = Color(0.7, 0.6, 1.0, 1.0)
	effect.scale = Vector2(1.8, 1.8)
	get_tree().current_scene.add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(effect, "scale", Vector2(3.0, 3.0), 0.25)
	tween.tween_callback(effect.queue_free)
