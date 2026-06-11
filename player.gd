## 玩家控制器：处理移动、跳跃、能力系统、碰撞检测和生命值管理
extends CharacterBody2D

const BASE_SPEED = 400.0
const PLAYER_SIZE = 64.0
const GRAVITY = 1200.0
const BASE_JUMP_FORCE = -600.0
const BASE_LIVES = 2
const BASE_INVINCIBLE_TIME = 1.5
const BASE_LANE_POSITIONS = [240, 360, 480]
var LANE_POSITIONS: Array = [240, 360, 480]

var current_lane_index: int = 1
var lane_switching: bool = false
var lane_switch_timer: float = 0.0
var last_lane_direction: int = 0
const LANE_SWITCH_DURATION: float = 0.06
var screen_width = 540.0
var screen_height = 1170.0
var ground_y = 1150.0
var is_jumping = false
var was_on_ground: bool = true
var game_running = true

var afterimage_timer: float = 0.0
var afterimage_interval: float = 0.04

var touch_start_pos: Vector2 = Vector2.ZERO
var touch_current_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false
const TOUCH_SWIPE_THRESHOLD: float = 30.0
const SKILL_ZONE_HEIGHT: float = 200.0
var _swipe_up_active: bool = false

var lives: int = BASE_LIVES
var max_lives: int = BASE_LIVES
var invincible: bool = false
var invincible_timer: float = 0.0

var fast_recovery_enabled: bool = false

var magnet_enabled: bool = false
var magnet_range: float = 300.0

var time_bomb_enabled: bool = false
var time_bomb_timer: float = 0.0
var time_bomb_interval: float = 5.0
var time_bomb_scene = preload("res://time_bomb.tscn")

var ricochet_dart_enabled: bool = false
var ricochet_dart_timer: float = 0.0
var ricochet_dart_interval: float = 6.0
var ricochet_dart_scene = preload("res://ricochet_dart.tscn")

var revenge_spirit_enabled: bool = false
var revenge_spirit_shield_active: bool = false
var revenge_spirit_cooldown: float = 15.0
var revenge_spirit_cooldown_timer: float = 0.0
var revenge_beam_scene = preload("res://revenge_beam.tscn")
var revenge_shield_sprite: Sprite2D = null

var last_direction: float = 1.0

var lucky_foot_first_bonus: bool = false

var auto_dodge_enabled: bool = false
var auto_dodge_cooldown: float = 5.0
var auto_dodge_cooldown_timer: float = 0.0
var auto_dodge_detect_range_y: float = 120.0
var auto_dodge_detect_range_x: float = 70.0
var auto_dodge_invincible_time: float = 0.2
var decoy_scene = preload("res://decoy_node.tscn")
var decoy_ability_enabled: bool = false
var decoy_cooldown: float = 10.0
var decoy_cooldown_timer: float = 0.0
var decoy_invincible_time: float = 3.0

var wall_phase_enabled: bool = false

var time_slow_enabled: bool = false
var time_slow_active: bool = false
var time_slow_duration: float = 3.0
var time_slow_timer: float = 0.0
var time_slow_cooldown: float = 12.0
var time_slow_cooldown_timer: float = 0.0
var time_slow_speed_mult: float = 0.25

var mirror_shield_enabled: bool = false
var mirror_shield_segments: int = 3
var mirror_shield_max_segments: int = 3
var mirror_shield_regen_timer: float = 0.0
var mirror_shield_regen_interval: float = 8.0
var mirror_shield_bars: Array = []

var satellite_enabled: bool = false
var satellite_count: int = 0
var satellite_max: int = 2
var satellite_nodes: Array = []
var satellite_scene = preload("res://satellite.tscn")

var flawless_challenge_enabled: bool = false
var flawless_no_damage_timer: float = 0.0
var flawless_required_time: float = 8.0
var flawless_bonus_active: bool = false
var flawless_score_mult: float = 1.5

var score_shield_enabled: bool = false
var score_shield_layers: int = 0
var score_shield_max_layers: int = 2
var score_shield_regen_timer: float = 0.0
var score_shield_regen_interval: float = 5.0
var score_shield_sprite: Sprite2D = null
var score_shield_label: Label = null

var survival_time: float = 0.0

var swap_enabled: bool = false
var swap_cooldown: float = 20.0
var swap_cooldown_timer: float = 0.0

var last_stand_enabled: bool = false
var last_stand_consumed: bool = false
var last_stand_hp: int = 20
var last_stand_active: bool = false
var last_stand_display_max: int = 0
var original_max_lives: int = 0  ## 最后一搏前的原始最大生命值，用于恢复判断

var phoenix_reborn_enabled: bool = false
var phoenix_reborn_cooldown: float = 15.0
var phoenix_reborn_cooldown_timer: float = 0.0
var phoenix_reborn_available: bool = false

var fire_nova_enabled: bool = false
var fire_nova_timer: float = 0.0
var fire_nova_interval: float = 6.0
var fire_nova_scene = preload("res://fire_nova.tscn")

var phantom_cloak_enabled: bool = false
var phantom_cloak_timer: float = 0.0
var phantom_cloak_interval: float = 8.0
var phantom_cloak_active: bool = false
var phantom_cloak_duration: float = 3.0
var phantom_cloak_active_timer: float = 0.0
var phantom_cloak_cooldown_after: float = 0.0

var life_recovery_enabled: bool = true
var life_recovery_timer: float = 0.0
var life_recovery_base_time: float = 10.0

var charged_jump_enabled: bool = false
var double_jump_available: bool = false
var double_jump_force: float = -450.0
var yoyo_enabled: bool = false
var yoyo_attack_timer: float = 0.0
var yoyo_attack_interval: float = 4.0

signal player_hit()
signal combo_changed(count: int, bonus_mult: float)

var _scan_throttle_timer: float = 0.0
const SCAN_THROTTLE_INTERVAL: float = 0.1

## 连击系统
var combo_count: int = 0
var _tracked_obstacles: Dictionary = {}
var _elite_hit: bool = false
const COMBO_DETECT_Y_OFFSET: float = 80.0
const COMBO_BONUS_TIERS: Array[Dictionary] = [
	{"min": 0, "bonus": 0.0},
	{"min": 5, "bonus": 0.05},
	{"min": 10, "bonus": 0.10},
	{"min": 20, "bonus": 0.20},
	{"min": 35, "bonus": 0.30}
]

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	var viewport = get_viewport()
	if viewport:
		screen_width = viewport.get_visible_rect().size.x
		screen_height = viewport.get_visible_rect().size.y
		ground_y = viewport.get_visible_rect().size.y - 130.0
		## 根据实际屏幕宽度动态计算三轨道X坐标
		var lane_spacing = screen_width / 4.0
		LANE_POSITIONS = [int(lane_spacing), int(lane_spacing * 2), int(lane_spacing * 3)]
	
	position.x = LANE_POSITIONS[current_lane_index]
	
	if sprite:
		sprite.texture = TextureGenerator.create_player_texture(64)

	## 监听游戏状态变化，选卡结束后重置触摸状态
	GameFlowManager.state_changed.connect(_on_game_state_changed)
	
	position.y = ground_y
	
	safe_margin = 8.0
	
	set_process_input(true)
	
	AbilityManager.ability_added.connect(_on_ability_added)
	AbilityManager.ability_stack_changed.connect(_on_ability_stack_changed)
	
	_refresh_stats()
	_check_fast_recovery_ability()
	_check_magnet_ability()
	_check_time_bomb_ability()
	_check_ricochet_dart_ability()
	_check_revenge_spirit_ability()
	_check_auto_dodge_ability()
	_check_decoy_ability()
	_check_wall_phase_ability()
	_check_time_slow_ability()
	_check_mirror_shield_ability()
	_check_satellite_ability()
	_check_flawless_challenge_ability()
	_check_score_shield_ability()
	_check_phantom_cloak_ability()
	_check_swap_ability()
	_check_last_stand_ability()
	_check_phoenix_reborn_ability()
	_check_charged_jump_ability()
	_check_yoyo_ability()
	_check_fire_nova_ability()

func _input(event):
	if not game_running:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			touch_current_pos = event.position
			is_touching = true
		else:
			_handle_swipe()
			## 向上滑动结束时释放 ui_up
			if _swipe_up_active:
				Input.action_release("ui_up")
				_swipe_up_active = false
			is_touching = false
	
	if event is InputEventScreenDrag:
		touch_current_pos = event.position
		## 实时检测向上滑动：超过阈值即按下 ui_up（模拟W键）
		if is_touching and not _swipe_up_active:
			var delta = touch_current_pos - touch_start_pos
			var abs_y = abs(delta.y)
			var abs_x = abs(delta.x)
			if abs_y > TOUCH_SWIPE_THRESHOLD and abs_y > abs_x and delta.y < 0:
				## 判断是否在UI区域（底部技能区域不触发）
				if touch_start_pos.y < screen_height - SKILL_ZONE_HEIGHT:
					Input.action_press("ui_up")
					_swipe_up_active = true

func _on_game_state_changed(new_state):
	## 从选卡/暂停恢复到游戏中时，重置触摸状态防止卡死
	if new_state == GameFlowManager.GameState.PLAYING:
		is_touching = false
		_swipe_up_active = false
		touch_start_pos = Vector2.ZERO
		touch_current_pos = Vector2.ZERO
		## 确保跳跃状态与实际位置同步
		if check_on_ground():
			is_jumping = false
			velocity.y = 0

func _handle_swipe():
	if not is_touching:
		return
	
	var delta = touch_current_pos - touch_start_pos
	var abs_x = abs(delta.x)
	var abs_y = abs(delta.y)
	
	if abs_x < TOUCH_SWIPE_THRESHOLD and abs_y < TOUCH_SWIPE_THRESHOLD:
		return
	
	if abs_x > abs_y:
		if delta.x > 0:
			if current_lane_index < LANE_POSITIONS.size() - 1:
				last_lane_direction = 1
				current_lane_index += 1
				lane_switching = true
				lane_switch_timer = LANE_SWITCH_DURATION
				last_direction = 1.0
			elif wall_phase_enabled and current_lane_index == LANE_POSITIONS.size() - 1:
				_trigger_wall_phase(1)
		else:
			if current_lane_index > 0:
				last_lane_direction = -1
				current_lane_index -= 1
				lane_switching = true
				lane_switch_timer = LANE_SWITCH_DURATION
				last_direction = -1.0
			elif wall_phase_enabled and current_lane_index == 0:
				_trigger_wall_phase(-1)
	else:
		if delta.y < 0:
			## 向上滑动：松手时兜底尝试跳跃
			## 关键：如果 _swipe_up_active=true，说明拖拽已经触发过跳跃，不要再重复触发！
			if not _swipe_up_active and touch_start_pos.y < screen_height - SKILL_ZONE_HEIGHT:
				if not is_jumping:
					if check_on_ground():
						var current_jump = AbilityManager.get_attribute_value("jump_force", BASE_JUMP_FORCE)
						velocity.y = current_jump
						is_jumping = true
						double_jump_available = charged_jump_enabled
				elif charged_jump_enabled and double_jump_available:
					_execute_double_jump()
		else:
			if touch_start_pos.y > screen_height - SKILL_ZONE_HEIGHT:
				try_use_skill()

func _physics_process(delta):
	if not game_running:
		return
	
	survival_time += delta
	_scan_throttle_timer += delta
	var should_scan = _scan_throttle_timer >= SCAN_THROTTLE_INTERVAL
	if should_scan:
		_scan_throttle_timer = 0.0
	
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			invincible = false
			modulate = Color(1, 1, 1, 1)
		else:
			if not phantom_cloak_active:
				var flash = sin(invincible_timer * 20.0) * 0.5 + 0.5
				modulate = Color(1, 1, 1, flash)
	
	var current_speed = AbilityManager.get_attribute_value("move_speed", BASE_SPEED)
	var current_jump = AbilityManager.get_attribute_value("jump_force", BASE_JUMP_FORCE)
	var jump_add = AbilityManager.get_attribute_value("jump_force_add", 0.0)
	current_jump += jump_add
	
	if lane_switching:
		lane_switch_timer -= delta
		if lane_switch_timer <= 0.0:
			lane_switching = false
			position.x = LANE_POSITIONS[current_lane_index]
			velocity.x = 0
		else:
			var progress = 1.0 - (lane_switch_timer / LANE_SWITCH_DURATION)
			var start_x = LANE_POSITIONS[current_lane_index - last_lane_direction]
			var end_x = LANE_POSITIONS[current_lane_index]
			## 极速切换：ease_out（快速启动，减速收尾），无过冲，地铁跑酷手感
			var eased = 1.0 - (1.0 - progress) * (1.0 - progress)
			position.x = lerp(start_x, end_x, eased)
			velocity.x = 0
	else:
		position.x = LANE_POSITIONS[current_lane_index]
		velocity.x = 0
		
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
			if current_lane_index > 0:
				last_lane_direction = -1
				current_lane_index -= 1
				lane_switching = true
				lane_switch_timer = LANE_SWITCH_DURATION
				last_direction = -1.0
			elif wall_phase_enabled and current_lane_index == 0:
				_trigger_wall_phase(-1)
		elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
			if current_lane_index < LANE_POSITIONS.size() - 1:
				last_lane_direction = 1
				current_lane_index += 1
				lane_switching = true
				lane_switch_timer = LANE_SWITCH_DURATION
				last_direction = 1.0
			elif wall_phase_enabled and current_lane_index == LANE_POSITIONS.size() - 1:
				_trigger_wall_phase(1)
	
	if not check_on_ground():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
		is_jumping = false
	
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_up"):
		if check_on_ground():
			velocity.y = current_jump
			is_jumping = true
			double_jump_available = charged_jump_enabled
		elif double_jump_available:
			_execute_double_jump()
	
	move_and_slide()
	
	if not wall_phase_enabled:
		position.x = clamp(position.x, PLAYER_SIZE / 2, screen_width - PLAYER_SIZE / 2)
	
	if position.y > ground_y:
		position.y = ground_y
		velocity.y = 0
		is_jumping = false
	
	if lane_switching:
		afterimage_timer -= delta
		if afterimage_timer <= 0.0:
			spawn_afterimage()
			afterimage_timer = afterimage_interval
	
	if abs(velocity.x) > 0:
		spawn_trail_particle()
	
	var on_ground_now = check_on_ground()
	if was_on_ground and not on_ground_now and is_jumping:
		spawn_jump_effect()
	if not was_on_ground and on_ground_now:
		spawn_land_effect()
	was_on_ground = on_ground_now
	
	if magnet_enabled and should_scan:
		_attract_coins()
	
	if should_scan:
		_process_combo_tracking()
	
	if time_bomb_enabled:
		time_bomb_timer -= delta
		if time_bomb_timer <= 0.0:
			_place_time_bomb()
			time_bomb_timer = time_bomb_interval
	
	if revenge_spirit_enabled:
		if revenge_spirit_cooldown_timer > 0.0:
			revenge_spirit_cooldown_timer -= delta
			if revenge_spirit_cooldown_timer <= 0.0:
				revenge_spirit_shield_active = true
				_update_revenge_shield_visual()
	
	if time_slow_enabled:
		if time_slow_active:
			time_slow_timer -= delta
			if time_slow_timer <= 0.0:
				_end_time_slow()
		if time_slow_cooldown_timer > 0.0:
			time_slow_cooldown_timer -= delta
		if Input.is_action_just_pressed("time_slow"):
			if not time_slow_active and time_slow_cooldown_timer <= 0.0:
				_trigger_time_slow()
				AbilityManager.skill_used.emit("time_slow")
	
	if flawless_challenge_enabled:
		if not flawless_bonus_active:
			flawless_no_damage_timer += delta
			if flawless_no_damage_timer >= flawless_required_time:
				_activate_flawless_bonus()
	
	if score_shield_enabled:
		_update_score_shield_visual()
		if score_shield_layers < score_shield_max_layers:
			score_shield_regen_timer += delta
			if score_shield_regen_timer >= score_shield_regen_interval:
				score_shield_layers += 1
				score_shield_regen_timer = 0.0
	
	if mirror_shield_enabled:
		_update_mirror_shield_regen(delta)
	
	if phantom_cloak_enabled:
		if phantom_cloak_active:
			phantom_cloak_active_timer -= delta
			_process_phantom_cloak_shader(delta)
			if phantom_cloak_active_timer <= 0.0:
				_end_phantom_cloak()
		elif phantom_cloak_cooldown_after > 0.0:
			phantom_cloak_cooldown_after -= delta
		else:
			phantom_cloak_timer -= delta
			if phantom_cloak_timer <= 0.0:
				_trigger_phantom_cloak()
	
	if phoenix_reborn_enabled:
		if not phoenix_reborn_available:
			phoenix_reborn_cooldown_timer -= delta
			if phoenix_reborn_cooldown_timer <= 0.0:
				phoenix_reborn_available = true
	
	if fire_nova_enabled:
		fire_nova_timer -= delta
		if fire_nova_timer <= 0.0:
			_trigger_fire_nova()
			fire_nova_timer = fire_nova_interval
	
	## 生命值恢复：最后一搏期间也要能恢复（基于原始 max_lives 判断）
	var effective_max = original_max_lives if last_stand_active else max_lives
	if lives < effective_max:
		life_recovery_timer += delta
		var recovery_time = _get_recovery_time()
		if life_recovery_timer >= recovery_time:
			lives = min(lives + 1, effective_max)
			if not last_stand_active:
				lives = min(lives, max_lives)
			life_recovery_timer = 0.0
	
	if swap_enabled:
		if swap_cooldown_timer > 0.0:
			swap_cooldown_timer -= delta
		if Input.is_action_just_pressed("swap"):
			if swap_cooldown_timer <= 0.0:
				_trigger_swap()
				AbilityManager.skill_used.emit("swap")
	
	if yoyo_enabled:
		yoyo_attack_timer -= delta
		if yoyo_attack_timer <= 0.0:
			_fire_yoyo_projectile()
			yoyo_attack_timer = yoyo_attack_interval
	
	if auto_dodge_enabled:
		if auto_dodge_cooldown_timer > 0.0:
			auto_dodge_cooldown_timer -= delta
		elif should_scan:
			_process_auto_dodge()
	
	if ricochet_dart_enabled:
		ricochet_dart_timer -= delta
		if ricochet_dart_timer <= 0.0:
			_fire_ricochet_dart()
			ricochet_dart_timer = ricochet_dart_interval
	
	if decoy_ability_enabled:
		if decoy_cooldown_timer > 0.0:
			decoy_cooldown_timer -= delta
		if Input.is_action_just_pressed("decoy"):
			if decoy_cooldown_timer <= 0.0:
				_trigger_decoy()
				AbilityManager.skill_used.emit("decoy")

func take_hit() -> bool:
	if invincible:
		return false
	if lives <= 0:
		return true
	
	if phantom_cloak_active and not _elite_hit:
		return false
	
	if _elite_hit:
		pass
	elif score_shield_enabled and score_shield_layers > 0:
		score_shield_layers -= 1
		_spawn_score_shield_shockwave()
		invincible = true
		invincible_timer = 0.5
		return false
	
	if _elite_hit:
		pass
	elif mirror_shield_enabled and mirror_shield_segments > 0:
		mirror_shield_segments -= 1
		_update_mirror_shield_bars()
		invincible = true
		invincible_timer = 0.3
		return false
	
	if _elite_hit:
		pass
	elif revenge_spirit_enabled and revenge_spirit_shield_active:
		revenge_spirit_shield_active = false
		revenge_spirit_cooldown_timer = revenge_spirit_cooldown
		_remove_revenge_shield_visual()
		_trigger_revenge_spirit()
		invincible = true
		invincible_timer = 0.3
		return false
	
	lives = max(lives - 1, 0)
	life_recovery_timer = 0.0
	
	_reset_combo()
	
	player_hit.emit()
	_spawn_hit_feedback()
	
	if flawless_challenge_enabled and flawless_bonus_active:
		_deactivate_flawless_bonus()
	flawless_no_damage_timer = 0.0
	
	if lives <= 0:
		## 优先级：凤凰复活 > 最后一搏（最后一搏期间死亡时，凤凰仍有机会救）
		if phoenix_reborn_enabled and phoenix_reborn_available:
			_trigger_phoenix_reborn()
			return false
		if last_stand_active:
			last_stand_active = false
			last_stand_display_max = 0
			return true
		if last_stand_enabled and not last_stand_consumed:
			_trigger_last_stand()
			return false
		return true
	
	invincible = true
	invincible_timer = AbilityManager.get_attribute_value("invincible_duration", BASE_INVINCIBLE_TIME)
	
	return false

func get_lives() -> int:
	return lives

func get_max_lives() -> int:
	if last_stand_active:
		return last_stand_display_max
	return max_lives

func get_flawless_time() -> float:
	if flawless_challenge_enabled:
		return flawless_no_damage_timer
	return 0.0

func get_combo_count() -> int:
	return combo_count

func set_elite_hit(value: bool):
	_elite_hit = value

func get_combo_bonus() -> float:
	for tier in COMBO_BONUS_TIERS:
		if combo_count >= tier["min"]:
			continue
		else:
			var idx = COMBO_BONUS_TIERS.find(tier)
			if idx > 0:
				return COMBO_BONUS_TIERS[idx - 1]["bonus"]
			return 0.0
	return COMBO_BONUS_TIERS[-1]["bonus"]

func _process_combo_tracking():
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	
	var detect_y = position.y + COMBO_DETECT_Y_OFFSET
	
	for obstacle in obstacles:
		if not is_instance_valid(obstacle):
			continue
		var obj_id = obstacle.get_instance_id()
		
		if _tracked_obstacles.has(obj_id):
			if _tracked_obstacles[obj_id] == "counted":
				continue
			if _tracked_obstacles[obj_id] == "tracking" and obstacle.position.y > detect_y:
				_tracked_obstacles[obj_id] = "counted"
				combo_count += 1
				combo_changed.emit(combo_count, 1.0 + get_combo_bonus())
		else:
			if obstacle.position.y < position.y - 50.0:
				_tracked_obstacles[obj_id] = "tracking"
	
	var to_erase: Array = []
	for obj_id in _tracked_obstacles:
		if _tracked_obstacles[obj_id] == "counted":
			to_erase.append(obj_id)
	for obj_id in to_erase:
		_tracked_obstacles.erase(obj_id)

func _reset_combo():
	if combo_count > 0:
		combo_count = 0
		_tracked_obstacles.clear()
		combo_changed.emit(0, 1.0)

func _on_ability_added(_ability: AbilityData, _current_stacks: int):
	_refresh_stats()
	_check_fast_recovery_ability()
	_check_magnet_ability()
	_check_time_bomb_ability()
	_check_ricochet_dart_ability()
	_check_revenge_spirit_ability()
	_check_auto_dodge_ability()
	_check_decoy_ability()
	_check_wall_phase_ability()
	_check_time_slow_ability()
	_check_mirror_shield_ability()
	_check_satellite_ability()
	_check_flawless_challenge_ability()
	_check_score_shield_ability()
	_check_swap_ability()
	_check_last_stand_ability()
	_check_phoenix_reborn_ability()
	_check_charged_jump_ability()
	_check_yoyo_ability()
	_check_fire_nova_ability()
	_check_phantom_cloak_ability()
	
	if _ability.ability_id == "lucky_rabbit_foot" and AbilityManager.ability_add_count == 1:
		lucky_foot_first_bonus = true

func _on_ability_stack_changed(ability_id: String, _new_stacks: int):
	_refresh_stats()
	_check_satellite_ability()
	_check_fast_recovery_ability()
	_check_score_shield_ability()
	if ability_id == "mirror_shield":
		_check_mirror_shield_ability()

func _check_fast_recovery_ability():
	if AbilityManager.has_ability("fast_recovery"):
		fast_recovery_enabled = true

func _check_magnet_ability():
	if AbilityManager.has_ability("magnet_gloves"):
		magnet_enabled = true

func _check_time_bomb_ability():
	if AbilityManager.has_ability("time_bomb"):
		time_bomb_enabled = true
		time_bomb_timer = time_bomb_interval

func _check_ricochet_dart_ability():
	if AbilityManager.has_ability("ricochet_dart"):
		ricochet_dart_enabled = true
		ricochet_dart_timer = ricochet_dart_interval

func _check_revenge_spirit_ability():
	if AbilityManager.has_ability("revenge_spirit"):
		revenge_spirit_enabled = true
		if not revenge_spirit_shield_active and revenge_spirit_cooldown_timer <= 0.0:
			revenge_spirit_shield_active = true
			_update_revenge_shield_visual()
	else:
		if revenge_spirit_enabled:
			revenge_spirit_enabled = false
			revenge_spirit_shield_active = false
			_remove_revenge_shield_visual()

func _check_auto_dodge_ability():
	if AbilityManager.has_ability("auto_dodge"):
		auto_dodge_enabled = true

func _check_decoy_ability():
	if AbilityManager.has_ability("decoy"):
		decoy_ability_enabled = true

func _process_auto_dodge():
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	var threat = null
	var min_dist = 9999.0
	
	for obstacle in obstacles:
		if not is_instance_valid(obstacle):
			continue
		var dx = abs(position.x - obstacle.position.x)
		var dy = position.y - obstacle.position.y
		if dx < auto_dodge_detect_range_x and dy > 0 and dy < auto_dodge_detect_range_y:
			if dx < min_dist:
				min_dist = dx
				threat = obstacle
	
	if threat == null:
		return
	
	var safe_lanes = []
	for i in range(LANE_POSITIONS.size()):
		if i == current_lane_index:
			continue
		var lane_x = LANE_POSITIONS[i]
		var is_safe = true
		for obstacle in obstacles:
			if not is_instance_valid(obstacle):
				continue
			var odx = abs(obstacle.position.x - lane_x)
			var ody = position.y - obstacle.position.y
			if odx < 60 and ody > 0 and ody < auto_dodge_detect_range_y:
				is_safe = false
				break
		if is_safe:
			safe_lanes.append(i)
	
	var target_lane: int
	if safe_lanes.size() > 0:
		target_lane = safe_lanes[randi() % safe_lanes.size()]
	else:
		var other_lanes = []
		for i in range(LANE_POSITIONS.size()):
			if i != current_lane_index:
				other_lanes.append(i)
		if other_lanes.is_empty():
			return
		target_lane = other_lanes[randi() % other_lanes.size()]
	
	var old_lane = current_lane_index
	current_lane_index = target_lane
	lane_switching = true
	lane_switch_timer = LANE_SWITCH_DURATION
	last_lane_direction = 1 if target_lane > old_lane else -1
	
	invincible = true
	invincible_timer = auto_dodge_invincible_time
	
	auto_dodge_cooldown_timer = auto_dodge_cooldown

func _trigger_decoy():
	decoy_cooldown_timer = decoy_cooldown
	## 重置触摸状态
	is_touching = false
	_swipe_up_active = false
	touch_start_pos = Vector2.ZERO
	touch_current_pos = Vector2.ZERO
	
	var decoy = decoy_scene.instantiate()
	decoy.position = position
	get_parent().add_child(decoy)
	
	invincible = true
	invincible_timer = decoy_invincible_time
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(0.6, 0.8, 1.0, 0.6), 0.05)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func _check_wall_phase_ability():
	if AbilityManager.has_ability("wall_phase"):
		wall_phase_enabled = true

func _trigger_wall_phase(direction: int):
	if direction > 0:
		current_lane_index = 0
	else:
		current_lane_index = LANE_POSITIONS.size() - 1
	position.x = LANE_POSITIONS[current_lane_index]
	lane_switching = false
	last_direction = float(direction)

func _execute_double_jump():
	velocity.y = double_jump_force
	double_jump_available = false
	is_jumping = true
	
	var jump_effect = Sprite2D.new()
	jump_effect.texture = TextureGenerator.create_particle_texture(16)
	jump_effect.position = position
	jump_effect.modulate = Color(0.7, 0.6, 1.0, 0.8)
	jump_effect.scale = Vector2(1.5, 1.5)
	get_parent().add_child(jump_effect)
	
	var tween = jump_effect.create_tween()
	tween.tween_property(jump_effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(jump_effect, "scale", Vector2(2.5, 2.5), 0.3)
	tween.tween_callback(jump_effect.queue_free)

func _check_time_slow_ability():
	if AbilityManager.has_ability("time_slow"):
		time_slow_enabled = true

func _trigger_time_slow():
	time_slow_active = true
	time_slow_timer = time_slow_duration
	time_slow_cooldown_timer = time_slow_cooldown
	## 重置触摸状态
	is_touching = false
	_swipe_up_active = false
	touch_start_pos = Vector2.ZERO
	touch_current_pos = Vector2.ZERO
	
	AbilityManager.apply_temporary_multiplier("obstacle_speed", time_slow_speed_mult)
	AbilityManager.set_meta("time_slow_active", true)
	
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		if is_instance_valid(obstacle) and obstacle.has_method("apply_time_slow"):
			obstacle.apply_time_slow(time_slow_speed_mult, time_slow_duration)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(0.4, 0.6, 1.0, 0.7), 0.1)
	flash_tween.tween_property(self, "modulate", Color(0.6, 0.7, 1.0, 0.8), 0.3)

func _end_time_slow():
	time_slow_active = false
	
	AbilityManager.remove_temporary_multiplier("obstacle_speed", time_slow_speed_mult)
	AbilityManager.set_meta("time_slow_active", false)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func _check_mirror_shield_ability():
	if AbilityManager.has_ability("mirror_shield"):
		if not mirror_shield_enabled:
			mirror_shield_enabled = true
			mirror_shield_segments = mirror_shield_max_segments
			_update_mirror_shield_bars()
	else:
		if mirror_shield_enabled:
			mirror_shield_enabled = false
			mirror_shield_segments = 0
			_clear_mirror_shield_bars()

func _clear_mirror_shield_bars():
	for bar in mirror_shield_bars:
		if is_instance_valid(bar):
			bar.queue_free()
	mirror_shield_bars.clear()

func _check_satellite_ability():
	var stacks = AbilityManager.get_ability_stacks("satellite")
	if stacks > 0:
		satellite_enabled = true
		while satellite_count < min(stacks, satellite_max):
			_spawn_satellite(satellite_count)
			satellite_count += 1
	else:
		if satellite_enabled:
			satellite_enabled = false
			_remove_all_satellites()

func _spawn_satellite(index: int):
	var node = satellite_scene.instantiate()
	
	if index == 0:
		node.orbit_radius = 70.0
		node.orbit_speed = 3.0
		node.satellite_size = 32.0
	elif index == 1:
		node.orbit_radius = 110.0
		node.orbit_speed = -2.0
		node.satellite_size = 28.0
	
	add_child(node)
	satellite_nodes.append(node)

func _remove_all_satellites():
	for node in satellite_nodes:
		if node and is_instance_valid(node):
			node.queue_free()
	satellite_nodes.clear()
	satellite_count = 0

func _check_flawless_challenge_ability():
	if AbilityManager.has_ability("flawless_challenge"):
		flawless_challenge_enabled = true
	else:
		if flawless_challenge_enabled:
			if flawless_bonus_active:
				_deactivate_flawless_bonus()
			flawless_challenge_enabled = false
			flawless_no_damage_timer = 0.0

func _activate_flawless_bonus():
	flawless_bonus_active = true
	
	AbilityManager.apply_temporary_multiplier("score_multiplier", 1.0 + flawless_score_mult)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.3, 1.0), 0.15)
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.95, 0.6, 1.0), 0.3)

func _deactivate_flawless_bonus():
	flawless_bonus_active = false
	
	AbilityManager.remove_temporary_multiplier("score_multiplier", 1.0 + flawless_score_mult)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1, 0.3, 0.3, 1.0), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)

func _check_score_shield_ability():
	if AbilityManager.has_ability("score_shield"):
		if not score_shield_enabled:
			score_shield_enabled = true
			score_shield_layers = 1
			score_shield_regen_timer = 0.0
			_spawn_score_shield_visual()
	else:
		if score_shield_enabled:
			score_shield_enabled = false
			score_shield_layers = 0
			_remove_score_shield_visual()

func _place_time_bomb():
	var bomb = time_bomb_scene.instantiate()
	bomb.position = position
	get_parent().add_child(bomb)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.6, 0.2, 1.0), 0.05)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func _check_swap_ability():
	if AbilityManager.has_ability("swap"):
		swap_enabled = true
	else:
		if swap_enabled:
			swap_enabled = false

func _trigger_swap():
	swap_cooldown_timer = swap_cooldown
	## 重置触摸状态，防止技能按钮的触摸干扰后续跳跃
	is_touching = false
	_swipe_up_active = false
	touch_start_pos = Vector2.ZERO
	touch_current_pos = Vector2.ZERO
	
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	if obstacles.size() == 0:
		return
	
	var target = obstacles[randi() % obstacles.size()]
	if not is_instance_valid(target):
		return
	
	var player_pos = position
	var target_pos = target.position
	
	position.x = target_pos.x  ## 只取X坐标换位，Y保持不变
	target.queue_free()
	
	## 确保X在合法轨道范围内
	var closest_lane = current_lane_index
	var min_dist = absf(position.x - LANE_POSITIONS[0])
	for i in range(LANE_POSITIONS.size()):
		var dist = absf(position.x - LANE_POSITIONS[i])
		if dist < min_dist:
			min_dist = dist
			closest_lane = i
	current_lane_index = closest_lane
	lane_switching = false
	
	## 重置跳跃状态，防止卡死
	if check_on_ground():
		is_jumping = false
		velocity.y = 0
	
	invincible = true
	invincible_timer = 0.3
	
	_clear_all_obstacles()
	_spawn_swap_effect(player_pos, target_pos)

func _spawn_swap_effect(from: Vector2, to: Vector2):
	for pos in [from, to]:
		var effect = Sprite2D.new()
		effect.texture = TextureGenerator.create_particle_texture(24)
		effect.position = pos
		effect.modulate = Color(1.0, 0.5, 1.0, 1.0)
		effect.scale = Vector2(2.5, 2.5)
		get_parent().add_child(effect)
		
		var tween = effect.create_tween()
		tween.tween_property(effect, "modulate:a", 0.0, 0.4)
		tween.parallel().tween_property(effect, "scale", Vector2(4.0, 4.0), 0.4)
		tween.tween_callback(effect.queue_free)

func _check_last_stand_ability():
	if AbilityManager.has_ability("last_stand"):
		last_stand_enabled = true
		last_stand_consumed = false
	else:
		if last_stand_enabled:
			last_stand_enabled = false
			last_stand_consumed = true

func _trigger_last_stand():
	last_stand_consumed = true
	last_stand_active = true
	last_stand_display_max = last_stand_hp

	var old_max = max_lives
	original_max_lives = old_max  ## 保存原始最大生命值用于恢复判断
	max_lives = last_stand_hp
	lives = last_stand_hp
	
	invincible = true
	invincible_timer = 1.0
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(0.2, 1.0, 0.3, 1.0), 0.05)
	flash_tween.tween_property(self, "modulate", Color(0.3, 1.0, 0.5, 1.0), 0.15)
	flash_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)

func _attract_coins():
	var coins = get_tree().get_nodes_in_group("coins")
	for coin in coins:
		if not is_instance_valid(coin):
			continue
		var dist = position.distance_to(coin.position)
		if dist <= magnet_range:
			coin.attracted = true

func _fire_ricochet_dart():
	var dart = ricochet_dart_scene.instantiate()
	dart.position = Vector2(position.x, position.y - PLAYER_SIZE / 2)
	dart.direction = Vector2.UP
	dart.homing_enabled = true
	get_parent().add_child(dart)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(0.3, 0.9, 0.8, 1.0), 0.05)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func _trigger_revenge_spirit():
	revenge_spirit_cooldown_timer = revenge_spirit_cooldown
	
	var beam = revenge_beam_scene.instantiate()
	beam.position = Vector2(position.x, position.y - PLAYER_SIZE / 2)
	call_deferred("add_child_deferred", beam)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(0.8, 0.3, 1.0, 1.0), 0.05)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func try_use_skill():
	## 使用技能后重置触摸状态，防止技能区域的触摸起点干扰后续滑动跳跃
	is_touching = false
	_swipe_up_active = false
	touch_start_pos = Vector2.ZERO
	touch_current_pos = Vector2.ZERO

	if time_slow_enabled and not time_slow_active and time_slow_cooldown_timer <= 0.0:
		_trigger_time_slow()
		AbilityManager.skill_used.emit("time_slow")
	elif decoy_ability_enabled and decoy_cooldown_timer <= 0.0:
		_trigger_decoy()
		AbilityManager.skill_used.emit("decoy")
	elif swap_enabled and swap_cooldown_timer <= 0.0:
		_trigger_swap()
		AbilityManager.skill_used.emit("swap")

func _refresh_stats():
	var old_max_lives = max_lives
	max_lives = int(AbilityManager.get_attribute_value("max_lives", BASE_LIVES))
	
	if max_lives > old_max_lives:
		lives += (max_lives - old_max_lives)
	
	if lives > max_lives:
		lives = max_lives
	elif lives <= 0 and max_lives > 0:
		lives = 1
	
	var collision_scale = AbilityManager.get_attribute_value("collision_scale", 1.0)
	if lucky_foot_first_bonus:
		collision_scale -= 0.15
	if collision_shape:
		collision_shape.scale = Vector2(collision_scale, collision_scale)
	if sprite:
		sprite.scale = Vector2(collision_scale, collision_scale)

func spawn_trail_particle():
	var particle = Sprite2D.new()
	particle.texture = TextureGenerator.create_particle_texture(12)
	particle.position = position
	particle.modulate = Color(0.3, 0.7, 1.0, 0.8)
	particle.scale = Vector2(0.8, 0.8)
	get_parent().add_child(particle)
	
	var tween = create_tween()
	tween.tween_property(particle, "modulate:a", 0.0, 0.3)
	tween.tween_callback(particle.queue_free)

func spawn_afterimage():
	var afterimage = Sprite2D.new()
	afterimage.texture = TextureGenerator.create_afterimage_texture(64)
	afterimage.position = position
	afterimage.modulate = Color(0.3, 0.7, 1.0, 0.4)
	afterimage.scale = sprite.scale if sprite else Vector2.ONE
	get_parent().add_child(afterimage)
	
	var tween = create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(afterimage, "scale", afterimage.scale * 1.3, 0.25)
	tween.tween_callback(afterimage.queue_free)

func spawn_jump_effect():
	for i in range(6):
		var angle = (i / 6.0) * PI * 2.0
		var particle = Sprite2D.new()
		particle.texture = TextureGenerator.create_particle_texture(8)
		particle.position = position + Vector2(0, PLAYER_SIZE / 2)
		particle.modulate = Color(0.4, 0.8, 1.0, 0.9)
		particle.scale = Vector2(0.6, 0.6)
		get_parent().add_child(particle)
		
		var target_pos = particle.position + Vector2(cos(angle), sin(angle)) * 30.0
		var tween = create_tween()
		tween.tween_property(particle, "position", target_pos, 0.25)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.25)
		tween.tween_callback(particle.queue_free)

func spawn_land_effect():
	for i in range(8):
		var angle = PI + (i / 8.0) * PI
		var particle = Sprite2D.new()
		particle.texture = TextureGenerator.create_particle_texture(10)
		particle.position = position + Vector2(0, PLAYER_SIZE / 2)
		particle.modulate = Color(0.5, 0.7, 1.0, 0.8)
		particle.scale = Vector2(0.7, 0.7)
		get_parent().add_child(particle)
		
		var target_pos = particle.position + Vector2(cos(angle), sin(angle)) * 40.0
		var tween = create_tween()
		tween.tween_property(particle, "position", target_pos, 0.3)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(particle.queue_free)

func check_on_ground() -> bool:
	return position.y >= ground_y - 5

func stop():
	game_running = false
	velocity = Vector2.ZERO

func grant_pool_exhausted_bonus():
	invincible = true
	invincible_timer = 3.0
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.3, 0.6), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.3, 0.6), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.3, 0.6), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func _check_phoenix_reborn_ability():
	if AbilityManager.has_ability("phoenix_reborn"):
		if not phoenix_reborn_enabled:
			phoenix_reborn_enabled = true
			phoenix_reborn_available = true
			phoenix_reborn_cooldown_timer = 0.0
	else:
		if phoenix_reborn_enabled:
			phoenix_reborn_enabled = false
			phoenix_reborn_available = false

func _trigger_phoenix_reborn():
	phoenix_reborn_available = false
	phoenix_reborn_cooldown_timer = phoenix_reborn_cooldown
	lives = max_lives
	invincible = true
	invincible_timer = 2.0
	
	_clear_all_obstacles()
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.8, 0.2, 1.0), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.5, 0.1, 1.0), 0.1)
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.3, 1.0), 0.15)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	
	for i in range(12):
		var angle = (i / 12.0) * PI * 2.0
		var particle = Sprite2D.new()
		particle.texture = TextureGenerator.create_fire_texture(24, 32)
		particle.position = position
		particle.modulate = Color(1.0, 0.6, 0.1, 1.0)
		particle.scale = Vector2(1.5, 1.5)
		get_parent().add_child(particle)
		var target_pos = position + Vector2(cos(angle), sin(angle)) * 120.0
		var tween = create_tween()
		tween.tween_property(particle, "position", target_pos, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func _check_fire_nova_ability():
	if AbilityManager.has_ability("fire_nova"):
		fire_nova_enabled = true
		fire_nova_timer = fire_nova_interval

func _trigger_fire_nova():
	var nova = fire_nova_scene.instantiate()
	nova.position = position
	get_parent().add_child(nova)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.5, 0.1, 1.0), 0.05)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)

func _check_phantom_cloak_ability():
	if AbilityManager.has_ability("phantom_cloak"):
		phantom_cloak_enabled = true
		phantom_cloak_timer = phantom_cloak_interval

func _trigger_phantom_cloak():
	phantom_cloak_active = true
	phantom_cloak_active_timer = phantom_cloak_duration
	phantom_cloak_timer = 0.0
	phantom_cloak_cooldown_after = 0.0
	_apply_phantom_cloak_visual(true)

func _end_phantom_cloak():
	phantom_cloak_active = false
	_apply_phantom_cloak_visual(false)
	phantom_cloak_cooldown_after = phantom_cloak_interval

func _apply_phantom_cloak_visual(active: bool):
	if active:
		var shader_mat = ShaderMaterial.new()
		var shader_code = """
shader_type canvas_item;

uniform float u_time;
uniform float u_intensity;

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5);
	vec2 p = uv - center;
	float dist = length(p);
	float angle = atan(p.y, p.x);
	
	float twist = u_intensity * sin(u_time * 3.14159) * (1.0 - dist);
	float new_angle = angle + twist;
	
	vec2 twisted_p = vec2(cos(new_angle), sin(new_angle)) * dist;
	vec2 twisted_uv = twisted_p + center;
	
	float fade = 1.0 - u_intensity * 0.7;
	
	COLOR = texture(TEXTURE, twisted_uv);
	COLOR.a *= fade;
}
"""
		shader_mat.shader = Shader.new()
		shader_mat.shader.code = shader_code
		shader_mat.set_shader_parameter("u_time", 0.0)
		shader_mat.set_shader_parameter("u_intensity", 0.0)
		sprite.material = shader_mat
		
		var tween = create_tween()
		tween.tween_method(func(v): shader_mat.set_shader_parameter("u_intensity", v), 0.0, 1.0, 0.3)
		tween.tween_property(self, "modulate", Color(0.5, 0.8, 1.0, 0.3), 0.1)
	else:
		if sprite.material and sprite.material is ShaderMaterial:
			var shader_mat = sprite.material as ShaderMaterial
			var tween = create_tween()
			tween.tween_method(func(v): shader_mat.set_shader_parameter("u_intensity", v), 1.0, 0.0, 0.3)
			tween.tween_callback(func():
				sprite.material = null
				modulate = Color(1, 1, 1, 1)
			)
		else:
			modulate = Color(1, 1, 1, 1)

func _process_phantom_cloak_shader(delta):
	if phantom_cloak_active and sprite.material and sprite.material is ShaderMaterial:
		var shader_mat = sprite.material as ShaderMaterial
		var current_time = shader_mat.get_shader_parameter("u_time")
		shader_mat.set_shader_parameter("u_time", current_time + delta)

func _get_recovery_time() -> float:
	var stacks = AbilityManager.get_ability_stacks("fast_recovery")
	match stacks:
		0:
			return life_recovery_base_time
		1:
			return 7.0
		2:
			return 5.0
		_:
			return 3.0

func _clear_all_obstacles():
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			_spawn_obstacle_destroy_effect(obstacle.global_position)
			obstacle.queue_free()
	
	var shockwave = Sprite2D.new()
	shockwave.texture = TextureGenerator.create_particle_texture(64)
	shockwave.position = position
	shockwave.modulate = Color(1.0, 0.9, 0.3, 0.6)
	shockwave.scale = Vector2(0.5, 0.5)
	get_parent().add_child(shockwave)
	var tween = create_tween()
	tween.tween_property(shockwave, "scale", Vector2(20.0, 20.0), 0.4)
	tween.parallel().tween_property(shockwave, "modulate:a", 0.0, 0.4)
	tween.tween_callback(shockwave.queue_free)

func _spawn_obstacle_destroy_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(12)
	effect.position = pos
	effect.modulate = Color(1.0, 0.4, 0.2, 0.8)
	effect.scale = Vector2(1.0, 1.0)
	get_parent().add_child(effect)
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(effect, "scale", Vector2(2.0, 2.0), 0.2)
	tween.tween_callback(effect.queue_free)

func _spawn_hit_feedback():
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_pos = camera.position
		var shake_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		var shake_tween = create_tween()
		shake_tween.tween_property(camera, "position", original_pos + shake_offset, 0.03)
		shake_tween.tween_property(camera, "position", original_pos, 0.15)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.2, 0.2, 0.8), 0.05)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	
	for i in range(6):
		var angle = randf() * PI * 2.0
		var particle = Sprite2D.new()
		particle.texture = TextureGenerator.create_particle_texture(8)
		particle.position = position
		particle.modulate = Color(1.0, 0.3, 0.2, 0.8)
		particle.scale = Vector2(0.8, 0.8)
		get_parent().add_child(particle)
		var target_pos = position + Vector2(cos(angle), sin(angle)) * 25.0
		var p_tween = create_tween()
		p_tween.tween_property(particle, "position", target_pos, 0.2)
		p_tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.2)
		p_tween.tween_callback(particle.queue_free)

func _spawn_score_shield_visual():
	if score_shield_sprite and is_instance_valid(score_shield_sprite):
		return
	score_shield_sprite = Sprite2D.new()
	score_shield_sprite.texture = TextureGenerator.create_shield_texture(80)
	score_shield_sprite.z_index = 1
	add_child(score_shield_sprite)
	
	score_shield_label = Label.new()
	score_shield_label.text = "0"
	score_shield_label.add_theme_font_size_override("font_size", 32)
	score_shield_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1, 1.0))
	score_shield_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	score_shield_label.add_theme_constant_override("outline_size", 3)
	score_shield_label.position = Vector2(-20, -20)
	score_shield_label.size = Vector2(40, 40)
	score_shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_shield_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_shield_label.z_index = 2
	add_child(score_shield_label)

func _remove_score_shield_visual():
	if score_shield_sprite and is_instance_valid(score_shield_sprite):
		score_shield_sprite.queue_free()
		score_shield_sprite = null
	score_shield_label = null
	if sprite and is_instance_valid(sprite):
		sprite.modulate = Color(1, 1, 1, 1)

func _update_score_shield_visual():
	if not score_shield_sprite or not is_instance_valid(score_shield_sprite):
		return
	if score_shield_layers > 0:
		if sprite and is_instance_valid(sprite):
			sprite.modulate = Color(1.0, 0.9, 0.2, 1.0)
		score_shield_sprite.modulate = Color(1.0, 0.9, 0.2, 0.15)
		var pulse = 1.0 + sin(Time.get_ticks_msec() / 400.0) * 0.05
		score_shield_sprite.scale = Vector2(pulse, pulse)
		if score_shield_label:
			score_shield_label.text = str(score_shield_layers)
			score_shield_label.visible = true
	else:
		if sprite and is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1, 1)
		score_shield_sprite.modulate = Color(1.0, 0.9, 0.2, 0.05)
		if score_shield_label:
			score_shield_label.visible = false

func _update_revenge_shield_visual():
	if not revenge_spirit_shield_active:
		_remove_revenge_shield_visual()
		return
	
	if not revenge_shield_sprite or not is_instance_valid(revenge_shield_sprite):
		revenge_shield_sprite = Sprite2D.new()
		revenge_shield_sprite.texture = TextureGenerator.create_shield_texture(90)
		revenge_shield_sprite.z_index = 1
		add_child(revenge_shield_sprite)
	
	var t = Time.get_ticks_msec() / 1000.0
	var pulse = 1.0 + sin(t * 4.0) * 0.08
	revenge_shield_sprite.scale = Vector2(pulse, pulse)
	var alpha = 0.4 + sin(t * 3.0) * 0.15
	revenge_shield_sprite.modulate = Color(0.8, 0.3, 1.0, alpha)
	revenge_shield_sprite.rotation = t * 1.5

func _remove_revenge_shield_visual():
	if revenge_shield_sprite and is_instance_valid(revenge_shield_sprite):
		revenge_shield_sprite.queue_free()
		revenge_shield_sprite = null

func _update_mirror_shield_regen(delta):
	if mirror_shield_segments < mirror_shield_max_segments:
		mirror_shield_regen_timer += delta
		if mirror_shield_regen_timer >= mirror_shield_regen_interval:
			mirror_shield_segments += 1
			mirror_shield_regen_timer = 0.0
			_update_mirror_shield_bars()

func _update_mirror_shield_bars():
	_clear_mirror_shield_bars()
	
	for i in range(mirror_shield_segments):
		var bar = Sprite2D.new()
		bar.texture = TextureGenerator.create_particle_texture(32)
		bar.position = Vector2(-25 + i * 25, -50)
		bar.modulate = Color(0.3, 0.7, 1.0, 0.8)
		bar.scale = Vector2(1.2, 0.6)
		add_child(bar)
		mirror_shield_bars.append(bar)

func _spawn_score_shield_shockwave():
	var shockwave_area = Area2D.new()
	shockwave_area.position = position
	shockwave_area.monitorable = false
	shockwave_area.collision_layer = 0
	shockwave_area.collision_mask = 1
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 150.0
	col.shape = circle
	shockwave_area.add_child(col)
	
	var effect_sprite = Sprite2D.new()
	effect_sprite.texture = TextureGenerator.create_particle_texture(64)
	effect_sprite.modulate = Color(1.0, 0.9, 0.3, 0.7)
	effect_sprite.scale = Vector2(0.1, 0.1)
	shockwave_area.add_child(effect_sprite)
	
	call_deferred("add_child_deferred", shockwave_area)
	
	var timer = get_tree().create_timer(0.05)
	timer.timeout.connect(func():
		if not is_instance_valid(shockwave_area):
			return
		shockwave_area.set_deferred("monitoring", true)
		call_deferred("_check_shockwave_hits", shockwave_area)
	)
	
	var tween = shockwave_area.create_tween()
	tween.tween_property(effect_sprite, "scale", Vector2(5.0, 5.0), 0.2)
	tween.parallel().tween_property(effect_sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(shockwave_area.queue_free)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.3, 1.0), 0.05)
	flash_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func add_child_deferred(node: Node) -> void:
	get_parent().add_child(node)

func _check_shockwave_hits(shockwave_area: Area2D) -> void:
	if not is_instance_valid(shockwave_area):
		return
	var bodies = shockwave_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("obstacles") and is_instance_valid(body):
			if body.is_in_group("energy_cores"):
				body.destroy_by_skill()
			else:
				body.queue_free()

func _check_charged_jump_ability():
	if AbilityManager.has_ability("charged_jump"):
		charged_jump_enabled = true

func _check_yoyo_ability():
	if AbilityManager.has_ability("yoyo"):
		if not yoyo_enabled:
			yoyo_enabled = true
			yoyo_attack_timer = yoyo_attack_interval

func _fire_yoyo_projectile():
	var projectile = Area2D.new()
	projectile.collision_layer = 0
	projectile.collision_mask = 1
	projectile.position = Vector2(position.x, position.y - 40)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	projectile.add_child(col)
	
	var proj_sprite = Sprite2D.new()
	proj_sprite.texture = TextureGenerator.create_particle_texture(24)
	proj_sprite.modulate = Color(1.0, 0.6, 0.2, 1.0)
	proj_sprite.scale = Vector2(1.2, 1.2)
	projectile.add_child(proj_sprite)
	
	projectile.area_entered.connect(_on_yoyo_hit_obstacle.bind(projectile))
	
	get_parent().add_child(projectile)
	
	var move_tween = projectile.create_tween()
	move_tween.tween_property(projectile, "position:y", -100.0, 1.5)
	move_tween.parallel().tween_property(proj_sprite, "modulate:a", 0.0, 1.5)
	move_tween.tween_callback(projectile.queue_free)

func _on_yoyo_hit_obstacle(area, projectile):
	if area.is_in_group("obstacles"):
		_spawn_yoyo_hit_effect(area.global_position)
		area.queue_free()
		if is_instance_valid(projectile):
			projectile.queue_free()

func _spawn_yoyo_hit_effect(pos: Vector2):
	var effect = Sprite2D.new()
	effect.texture = TextureGenerator.create_particle_texture(16)
	effect.position = pos
	effect.modulate = Color(1.0, 0.7, 0.3, 1.0)
	effect.scale = Vector2(2.0, 2.0)
	get_parent().add_child(effect)
	
	var tween = effect.create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(effect, "scale", Vector2(3.0, 3.0), 0.3)
	tween.tween_callback(effect.queue_free)
