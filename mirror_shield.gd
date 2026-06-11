## 镜之盾投射物：从玩家头顶射出的反弹盾牌
extends Area2D

var shield_width: float = 80.0
var shield_height: float = 16.0

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	if sprite:
		sprite.texture = _create_shield_texture()
	
	if collision_shape:
		var shape = RectangleShape2D.new()
		shape.size = Vector2(shield_width, shield_height)
		collision_shape.shape = shape
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(_delta):
	var pulse = sin(Time.get_ticks_msec() / 200.0) * 0.15 + 0.85
	modulate = Color(0.5, 0.8, 1.0, pulse)

func _on_body_entered(body):
	if body.name == "Player":
		return

func _on_area_entered(area):
	if not area.is_in_group("obstacles"):
		return
	
	if area.has_meta("reflected"):
		return
	
	area.set_meta("reflected", true)
	area.remove_from_group("obstacles")
	area.add_to_group("reflected_obstacles")
	
	if area.has_method("reflect"):
		area.reflect()
	
	_spawn_reflect_effect(area.global_position)

func _spawn_reflect_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(24)
	effect.position = pos
	effect.modulate = Color(0.5, 0.8, 1.0, 1.0)
	effect.scale = Vector2(2.0, 2.0)
	get_parent().get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(effect, "scale", Vector2(3.5, 3.5), 0.3)
	tween.tween_callback(effect.queue_free)

func _create_shield_texture() -> ImageTexture:
	var width = int(shield_width)
	var height = int(shield_height)
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	for x in range(width):
		for y in range(height):
			var edge_dist = min(x, width - 1 - x, y, height - 1 - y)
			var alpha = 1.0
			if edge_dist < 3:
				alpha = edge_dist / 3.0
			
			var r = 0.3 + 0.2 * (float(x) / float(width))
			var g = 0.6 + 0.2 * (float(y) / float(height))
			var b = 1.0
			image.set_pixel(x, y, Color(r, g, b, alpha))
	
	var texture = ImageTexture.create_from_image(image)
	return texture
