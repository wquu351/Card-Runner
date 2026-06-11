## 能量核心：特殊障碍物，被技能摧毁时触发爆炸清除整条轨道
extends Area2D

const BASE_SPEED = 400.0
var game_running = true
var screen_height = 1170.0
var speed_multiplier = 1.0
var has_damaged_player: bool = false
var lane_index: int = 1
var time_slow_factor: float = 1.0

@onready var sprite = $Sprite2D

func _ready():
	var viewport = get_viewport()
	if viewport:
		screen_height = viewport.get_visible_rect().size.y
	
	add_to_group("obstacles")
	add_to_group("energy_cores")
	
	if has_meta("speed_multiplier"):
		speed_multiplier = get_meta("speed_multiplier")
	
	if has_meta("lane_index"):
		lane_index = int(get_meta("lane_index"))
	
	_setup_visuals()
	_start_sparkle_effect()

func _setup_visuals() -> void:
	if sprite:
		sprite.texture = TextureGenerator.create_energy_core_texture(55)
		sprite.modulate = Color(1.0, 0.2, 0.15, 1.0)
	
	var glow = Sprite2D.new()
	glow.name = "Glow"
	glow.texture = TextureGenerator.create_glow_texture(80, Color(1.0, 0.3, 0.2))
	glow.modulate.a = 0.4
	glow.z_index = -1
	add_child(glow)

func _start_sparkle_effect() -> void:
	var timer = Timer.new()
	timer.name = "SparkleTimer"
	timer.wait_time = randf_range(0.05, 0.12)
	timer.autostart = true
	add_child(timer)
	
	timer.timeout.connect(_spawn_sparkle)

func _spawn_sparkle() -> void:
	var sparkle = Sprite2D.new()
	sparkle.name = "Sparkle"
	sparkle.texture = TextureGenerator.create_particle_texture(6)
	sparkle.position = Vector2(randf_range(-25, 25), randf_range(-30, 30))
	sparkle.modulate = Color(1.0, randf_range(0.5, 1.0), 0.2, 1.0)
	sparkle.scale = Vector2(randf_range(0.8, 1.4), randf_range(0.8, 1.4))
	add_child(sparkle)
	
	var tween = sparkle.create_tween()
	tween.tween_property(sparkle, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(sparkle, "position", sparkle.position + Vector2(randf_range(-10, 10), randf_range(-15, 5)), 0.15)
	tween.parallel().tween_property(sparkle, "scale", sparkle.scale * 0.3, 0.15)
	tween.tween_callback(sparkle.queue_free)

func _process(delta):
	if not game_running:
		return
	
	var ability_speed_mult = AbilityManager.get_attribute_value("obstacle_speed", 1.0)
	position.y += BASE_SPEED * speed_multiplier * ability_speed_mult * time_slow_factor * delta
	
	# 发光脉冲效果
	var glow_node = $Glow if has_node("Glow") else null
	if glow_node and is_instance_valid(glow_node):
		var pulse = 0.35 + sin(Time.get_ticks_msec() / 200.0) * 0.15
		glow_node.modulate.a = pulse
	
	if position.y > screen_height + 100:
		queue_free()

func apply_time_slow(factor: float, duration: float):
	time_slow_factor = factor
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if is_instance_valid(self):
			time_slow_factor = 1.0
	)

func destroy_by_skill() -> void:
	_trigger_explosion()

func _trigger_explosion() -> void:
	remove_from_group("obstacles")
	
	# 创建爆炸光圈
	_create_explosion_effect()
	
	# 清除同轨道上的所有障碍物
	_clear_lane_obstacles()

func _create_explosion_effect() -> void:
	# 主爆炸圈
	var explosion = Sprite2D.new()
	explosion.texture = TextureGenerator.create_explosion_ring(120)
	explosion.position = position
	explosion.modulate = Color(1.0, 0.3, 0.1, 1.0)
	explosion.scale = Vector2(0.3, 0.3)
	get_parent().add_child(explosion)
	
	var tween = explosion.create_tween()
	tween.tween_property(explosion, "scale", Vector2(3.0, 3.0), 0.4)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.4)
	tween.tween_callback(explosion.queue_free)
	
	# 爆炸粒子
	for i in range(16):
		var particle = Sprite2D.new()
		particle.texture = TextureGenerator.create_particle_texture(10)
		particle.position = position
		particle.modulate = Color(1.0, randf_range(0.3, 0.7), 0.1, 1.0)
		particle.scale = Vector2(1.2, 1.2)
		get_parent().add_child(particle)
		
		var angle = (i / 16.0) * PI * 2.0
		var target_pos = position + Vector2(cos(angle), sin(angle)) * randf_range(60, 100)
		
		var p_tween = particle.create_tween()
		p_tween.tween_property(particle, "position", target_pos, 0.35)
		p_tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.35)
		p_tween.parallel().tween_property(particle, "scale", Vector2(0.2, 0.2), 0.35)
		p_tween.tween_callback(particle.queue_free)

func _clear_lane_obstacles() -> void:
	const LANE_POSITIONS = [240, 360, 480]
	var lane_x = LANE_POSITIONS[lane_index]
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	
	for obstacle in obstacles:
		if not is_instance_valid(obstacle) or obstacle == self:
			continue
		
		if abs(obstacle.position.x - lane_x) < 50:
			obstacle.queue_free()

func _on_body_entered(body):
	if not body.name == "Player":
		return
	
	if not body.has_method("take_hit"):
		return
	
	var is_dead = body.take_hit()
	has_damaged_player = true
	
	if is_dead:
		var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
		if game_manager:
			game_manager.game_over()
	else:
		queue_free()

func stop():
	game_running = false
