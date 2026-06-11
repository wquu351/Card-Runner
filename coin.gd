## 金币：可收集的得分物品，支持磁铁吸引
extends Area2D

const BASE_FALL_SPEED = 200.0
const COIN_SCORE = 5
var game_running = true
var screen_height = 1170.0
var attracted: bool = false
var attract_speed: float = 600.0
var _player: Node2D = null

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	if sprite:
		sprite.texture = TextureGenerator.create_coin_texture(32)
	
	add_to_group("coins")
	body_entered.connect(_on_body_entered)

func _process(delta):
	if not game_running:
		return
	
	if attracted:
		if not _player:
			_player = get_tree().current_scene.get_node_or_null("Player")
		if _player and is_instance_valid(_player):
			var direction = (_player.position - position).normalized()
			position += direction * attract_speed * delta
			var dist = position.distance_to(_player.position)
			if dist < 30:
				_collect()
				return
	else:
		var ability_speed_mult = AbilityManager.get_attribute_value("obstacle_speed", 1.0)
		position.y += BASE_FALL_SPEED * ability_speed_mult * delta
	
	if position.y > screen_height + 50:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		_collect()

func _collect():
	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager and game_manager.has_method("add_score"):
		game_manager.add_score(COIN_SCORE)
	
	if AbilityManager.has_ability("coin_bonus"):
		AbilityManager.add_persistent_add_bonus("score_multiplier", 0.02)
	
	_spawn_collect_effect()
	queue_free()

func _spawn_collect_effect():
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = position
	effect.modulate = Color(1.0, 0.85, 0.2, 1.0)
	effect.scale = Vector2(1.5, 1.5)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func stop():
	game_running = false
