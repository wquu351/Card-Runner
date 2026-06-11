## 移动端控制：虚拟按键映射到输入动作
extends CanvasLayer

@onready var left_button: Button = $LeftButton
@onready var right_button: Button = $RightButton
@onready var jump_button: Button = $JumpButton
@onready var skill_button: Button = $SkillButton

var player: Node2D = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if left_button:
		left_button.button_down.connect(_on_left_down)
		left_button.button_up.connect(_on_left_up)
	
	if right_button:
		right_button.button_down.connect(_on_right_down)
		right_button.button_up.connect(_on_right_up)
	
	if jump_button:
		jump_button.button_down.connect(_on_jump_pressed)
	
	if skill_button:
		skill_button.button_down.connect(_on_skill_pressed)
	
	player = get_tree().current_scene.get_node_or_null("Player")

func _on_left_down():
	Input.action_press("ui_left")

func _on_left_up():
	Input.action_release("ui_left")

func _on_right_down():
	Input.action_press("ui_right")

func _on_right_up():
	Input.action_release("ui_right")

func _on_jump_pressed():
	Input.action_press("jump")
	await get_tree().create_timer(0.05).timeout
	Input.action_release("jump")

func _on_skill_pressed():
	if not player:
		return
	
	if player.has_method("try_use_skill"):
		player.try_use_skill()
