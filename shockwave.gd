## 冲击波：从玩家位置扩散的圆形冲击效果
extends Area2D

const LIFETIME = 0.4

var lifetime_timer: float = LIFETIME

@onready var sprite = $Sprite2D

func _ready():
	if sprite:
		sprite.texture = TextureGenerator.create_shockwave_texture(200, 60)
	
	area_entered.connect(_on_area_entered)
	
	scale = Vector2(0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta):
	lifetime_timer -= delta
	
	if lifetime_timer <= 0.0:
		queue_free()
		return
	
	var fade_ratio = lifetime_timer / LIFETIME
	modulate = Color(1, 1, 1, fade_ratio * 0.8)

func _on_area_entered(area):
	if area.is_in_group("obstacles"):
		_spawn_impact_effect(area.position)
		area.queue_free()

func _spawn_impact_effect(pos: Vector2):
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
