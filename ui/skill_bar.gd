## 技能栏UI：整合主动+被动双栏布局，移动端优化
extends Control

var _active_bar: Control = null
var _passive_bar: Control = null
var _stats_panel: Control = null
var _initialized: bool = false

func _ready():
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	_build_layout()
	get_tree().root.size_changed.connect(_on_screen_resize)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	_update_positions()
	_initialized = true

func _build_layout():
	for child in get_children():
		child.queue_free()
	
	var active_script = load("res://ui/active_skill_bar.gd")
	_active_bar = Control.new()
	_active_bar.set_script(active_script)
	_active_bar.name = "ActiveSkillBar"
	_active_bar.z_index = 10
	add_child(_active_bar)
	
	var passive_script = load("res://ui/passive_skill_bar.gd")
	_passive_bar = Control.new()
	_passive_bar.set_script(passive_script)
	_passive_bar.name = "PassiveSkillBar"
	_passive_bar.z_index = 10
	add_child(_passive_bar)
	
	var stats_script = load("res://ui/ability_stats_panel.gd")
	_stats_panel = Control.new()
	_stats_panel.set_script(stats_script)
	_stats_panel.name = "AbilityStatsPanel"
	_stats_panel.z_index = 10
	add_child(_stats_panel)

func _on_screen_resize():
	if _initialized:
		call_deferred("_update_positions")

func _update_positions():
	if not is_inside_tree():
		return
	
	var viewport = get_viewport()
	if not viewport:
		return
	
	var screen_size = viewport.get_visible_rect().size
	
	if screen_size.x <= 0 or screen_size.y <= 0:
		return
	
	if not _active_bar or not _passive_bar or not _stats_panel:
		return
	
	var active_width = 3 * (95 + 12) - 12
	var active_height = 75
	const GLOW_WIDTH = 3
	
	## 根据屏幕宽度自适应调整面板尺寸
	var scale_factor = clampf(screen_size.x / 720.0, 0.7, 1.0)
	
	var passive_width = int(171 * scale_factor)
	var stats_width = int(156 * scale_factor)
	
	var active_x = (screen_size.x - active_width) / 2.0
	var active_y = screen_size.y - active_height - 12
	
	## 被动栏放右上角，但避开生命值标签区域（生命值标签约占用右上角160px宽度）
	var passive_x = screen_size.x - passive_width - 4
	var passive_y = 70.0
	
	## 统计面板放左上角，但避开分数标签区域（分数标签约占用左上角200px宽度）
	var stats_x = 4.0
	var stats_y = 70.0
	
	_active_bar.position = Vector2(active_x, active_y)
	_active_bar.size = Vector2(active_width, active_height)
	
	_passive_bar.position = Vector2(passive_x, passive_y)
	
	_stats_panel.position = Vector2(stats_x, stats_y)

func _notification(what):
	if what == NOTIFICATION_RESIZED and _initialized:
		call_deferred("_update_positions")
