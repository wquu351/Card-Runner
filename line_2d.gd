extends Line2D

@export var speed: float = 350.0
@export var jump_force: float = -500.0
@export var gravity: float = 980.0
@export var max_tail_points: int = 25
@export var tail_width: float = 3.0

var tail_positions: Array[Vector2] = []
var player: CharacterBody2D

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	width = tail_width
	gradient = create_tail_gradient()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	handle_movement(delta)
	handle_jump()
	update_tail()

func handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	
	player.velocity.x = input_dir.x * speed
	player.velocity.y += gravity * delta
	player.move_and_slide()

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		player.velocity.y = jump_force

func update_tail() -> void:
	tail_positions.append(global_position)
	
	if tail_positions.size() > max_tail_points:
		tail_positions.pop_front()
	
	if not tail_positions.is_empty():
		points = PackedVector2Array(tail_positions)

func create_tail_gradient() -> Gradient:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0))
	grad.set_color(1, Color(1, 1, 1, 1))
	return grad
