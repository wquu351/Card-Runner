## 暂停菜单：游戏暂停界面，提供继续、重启和退出选项
extends CanvasLayer

signal resume_pressed
signal restart_pressed
signal quit_pressed

@onready var pause_button: Button = $VBoxContainer/PauseButton
@onready var pause_panel: PanelContainer = $PausePanel
@onready var resume_button: Button = $PausePanel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PausePanel/VBoxContainer/RestartButton
@onready var quit_button: Button = $PausePanel/VBoxContainer/QuitButton
@onready var vbox: VBoxContainer = $VBoxContainer

var is_paused: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if pause_panel:
		pause_panel.visible = false
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	## 运行时修正暂停按钮位置和样式
	_fix_pause_button()

func _fix_pause_button():
	## 修正 VBoxContainer 位置：右上角
	if vbox:
		vbox.anchor_left = 1.0
		vbox.anchor_right = 1.0
		vbox.anchor_top = 0.0
		vbox.anchor_bottom = 0.0
		vbox.offset_left = -80.0
		vbox.offset_top = 20.0
		vbox.offset_right = -20.0
		vbox.offset_bottom = 80.0
		vbox.grow_horizontal = 0
	
	## 为暂停按钮设置显式样式，防止手机端显示为黑色方块
	if pause_button:
		## 创建独立 Theme 资源，比 add_theme_stylebox_override 更可靠
		var btn_theme = Theme.new()
		
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
		normal_style.border_color = Color(0.7, 0.7, 0.8, 1.0)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(12)
		normal_style.set_content_margin_all(10)
		btn_theme.set_stylebox("normal", "Button", normal_style)
		
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = Color(0.3, 0.3, 0.45, 0.95)
		hover_style.border_color = Color(0.9, 0.9, 1.0, 1.0)
		btn_theme.set_stylebox("hover", "Button", hover_style)
		
		var pressed_style = normal_style.duplicate()
		pressed_style.bg_color = Color(0.15, 0.15, 0.25, 1.0)
		pressed_style.border_color = Color(1.0, 1.0, 1.0, 1.0)
		btn_theme.set_stylebox("pressed", "Button", pressed_style)
		
		var focus_style = normal_style.duplicate()
		focus_style.border_color = Color(1.0, 0.9, 0.4, 1.0)
		focus_style.set_border_width_all(3)
		btn_theme.set_stylebox("focus", "Button", focus_style)
		
		var disabled_style = normal_style.duplicate()
		disabled_style.bg_color = Color(0.1, 0.1, 0.15, 0.5)
		btn_theme.set_stylebox("disabled", "Button", disabled_style)
		
		pause_button.theme = btn_theme
		pause_button.visible = true
	
	## 同样为暂停面板内的按钮设置样式
	if pause_panel:
		var panel_theme = Theme.new()
		
		var panel_btn_normal = StyleBoxFlat.new()
		panel_btn_normal.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		panel_btn_normal.border_color = Color(0.5, 0.5, 0.6, 0.8)
		panel_btn_normal.set_border_width_all(1)
		panel_btn_normal.set_corner_radius_all(8)
		panel_btn_normal.set_content_margin_all(8)
		panel_theme.set_stylebox("normal", "Button", panel_btn_normal)
		
		var panel_btn_hover = panel_btn_normal.duplicate()
		panel_btn_hover.bg_color = Color(0.25, 0.25, 0.35, 0.95)
		panel_btn_hover.border_color = Color(0.7, 0.7, 0.8, 1.0)
		panel_theme.set_stylebox("hover", "Button", panel_btn_hover)
		
		var panel_btn_pressed = panel_btn_normal.duplicate()
		panel_btn_pressed.bg_color = Color(0.1, 0.1, 0.15, 1.0)
		panel_theme.set_stylebox("pressed", "Button", panel_btn_pressed)
		
		pause_panel.theme = panel_theme

func _on_pause_button_pressed():
	toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	
	if is_paused:
		pause_game()
	else:
		resume_game()

func pause_game():
	get_tree().paused = true
	is_paused = true
	
	if pause_panel:
		pause_panel.visible = true
	
	if pause_button:
		pause_button.text = ">"
	
	if resume_button:
		resume_button.grab_focus()

func resume_game():
	get_tree().paused = false
	is_paused = false
	
	if pause_panel:
		pause_panel.visible = false
	
	if pause_button:
		pause_button.text = "||"

func _on_resume_pressed():
	resume_game()
	resume_pressed.emit()

func _on_restart_pressed():
	resume_game()
	restart_pressed.emit()
	
	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager:
		game_manager.restart_game()
		get_tree().reload_current_scene()

func _on_quit_pressed():
	resume_game()
	quit_pressed.emit()
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()
