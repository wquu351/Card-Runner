extends Node2D

# 拖尾参数
@export var max_tail_length: float = 120.0  # 拖尾最大长度
@export var tail_point_count: int = 20  # 拖尾点数
@export var tail_width: float = 4.0  # 拖尾线宽度
@export var light_point_size: float = 12.0  # 光点大小
@export var light_speed: float = 250.0  # 光点移动速度
@export var tail_color: Color = Color(0.3, 0.7, 1.0, 1.0)  # 拖尾颜色
@export var light_color: Color = Color(1.0, 1.0, 1.0, 1.0)  # 光点颜色
@export var tail_fade_start: float = 0.3  # 拖尾从哪里开始淡出（0-1）

# 内部变量
var player: CharacterBody2D
var tail_positions: PackedVector2Array = PackedVector2Array()
var light_progress: float = 0.0  # 光点当前位置进度（0-1）
var tail_line: Line2D
var light_sprite: Sprite2D
var last_player_pos: Vector2 = Vector2.ZERO
var tail_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	# 获取父节点（玩家）
	player = get_parent() as CharacterBody2D
	if not player:
		queue_free()
		return
	
	# 初始化上一帧位置
	last_player_pos = player.global_position
	
	# 创建拖尾线
	tail_line = Line2D.new()
	tail_line.width = tail_width
	tail_line.default_color = tail_color
	tail_line.gradient = create_tail_gradient()
	add_child(tail_line)
	
	# 创建光点精灵
	light_sprite = Sprite2D.new()
	light_sprite.texture = create_light_texture()
	light_sprite.modulate = light_color
	add_child(light_sprite)
	
	# 初始化拖尾点
	initialize_tail()

func create_tail_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(tail_color.r, tail_color.g, tail_color.b, 0.0))
	gradient.add_point(tail_fade_start, Color(tail_color.r, tail_color.g, tail_color.b, 0.5))
	gradient.add_point(1.0, Color(tail_color.r, tail_color.g, tail_color.b, 1.0))
	return gradient

func create_light_texture() -> Texture2D:
	var image = Image.create(int(light_point_size * 2), int(light_point_size * 2), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var center = Vector2(light_point_size, light_point_size)
	var radius = light_point_size
	
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist < radius:
				var alpha = 1.0 - (dist / radius)
				alpha = pow(alpha, 1.5)  # 让边缘更柔和
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func initialize_tail() -> void:
	tail_positions.clear()
	var start_pos = player.global_position
	for i in range(tail_point_count):
		var t = float(i) / float(tail_point_count - 1)
		tail_positions.append(start_pos + Vector2(0, t * max_tail_length))  # 向下延伸
	light_progress = 0.0

func _physics_process(delta: float) -> void:
	if not player:
		return
	
	update_tail(delta)
	update_light(delta)
	update_visuals()

func update_tail(delta: float) -> void:
	# 计算玩家移动方向
	var player_movement = player.global_position - last_player_pos
	if player_movement.length_squared() > 0.1:
		# 有移动时，拖尾方向偏向移动反方向
		var desired_dir = -player_movement.normalized()
		# 结合向下的基础方向
		tail_direction = tail_direction.lerp((desired_dir + Vector2.DOWN * 0.5).normalized(), 5.0 * delta)
	else:
		# 没有移动时，拖尾回到向下方向
		tail_direction = tail_direction.lerp(Vector2.DOWN, 3.0 * delta)
	
	last_player_pos = player.global_position
	
	# 更新拖尾点位置 - 每个点平滑跟随前一个点
	for i in range(tail_positions.size()):
		if i == 0:
			# 第一个点直接跟随玩家
			tail_positions.set(i, player.global_position)
		else:
			# 其他点平滑跟随前一个点
			var prev_pos = tail_positions[i - 1]
			var current_pos = tail_positions[i]
			
			# 计算每个点之间的理想距离
			var segment_length = max_tail_length / float(tail_point_count - 1)
			
			# 目标位置：从前一个点按拖尾方向延伸
			var target_pos = prev_pos + tail_direction * segment_length
			
			# 平滑移动
			var smooth_factor = 12.0 * delta
			tail_positions.set(i, current_pos.lerp(target_pos, smooth_factor))

func update_light(delta: float) -> void:
	# 更新光点位置进度
	light_progress += (light_speed / max_tail_length) * delta
	
	# 循环光点
	if light_progress > 1.0:
		light_progress -= 1.0

func update_visuals() -> void:
	# 更新拖尾线
	var local_positions = PackedVector2Array()
	for pos in tail_positions:
		local_positions.append(to_local(pos))
	tail_line.points = local_positions
	
	# 更新光点位置
	if tail_positions.size() >= 2:
		var light_pos = get_position_on_tail(light_progress)
		light_sprite.global_position = light_pos

func get_position_on_tail(progress: float) -> Vector2:
	# progress: 0.0（拖尾末端）-> 1.0（玩家处）
	if tail_positions.size() < 2:
		return player.global_position
	
	# 反转进度，让0.0在末端，1.0在玩家处
	var t = 1.0 - progress
	
	# 计算在哪个线段上
	var total_segments = tail_positions.size() - 1
	var segment_index = int(t * float(total_segments))
	segment_index = clamp(segment_index, 0, total_segments - 1)
	
	var segment_t = (t * float(total_segments)) - float(segment_index)
	segment_t = clamp(segment_t, 0.0, 1.0)
	
	var start_pos = tail_positions[segment_index]
	var end_pos = tail_positions[segment_index + 1]
	
	return start_pos.lerp(end_pos, segment_t)

