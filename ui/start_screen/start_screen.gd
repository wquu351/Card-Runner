## 启动界面：标题、开始游戏按钮、卡牌百科面板
extends Control

signal start_game()

var _encyclopedia_visible: bool = false

func _enter_tree():
	process_mode = Node.PROCESS_MODE_ALWAYS

@onready var main_container: VBoxContainer = $MainContainer
@onready var title_label: Label = $MainContainer/TitleLabel
@onready var start_button: Button = $MainContainer/StartButton
@onready var encyclopedia_button: Button = $MainContainer/EncyclopediaButton
@onready var high_score_label: Label = $MainContainer/HighScoreLabel
@onready var enc_overlay: Control = $EncyclopediaOverlay
@onready var card_list: VBoxContainer = $EncyclopediaOverlay/EncInner/ScrollArea/CardList
@onready var close_btn: Button = $EncyclopediaOverlay/EncInner/HeaderRow/CloseBtn
@onready var bg_glow: ColorRect = $BgGlow

func _ready():
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_btn_hover.bind(start_button, true))
		start_button.mouse_exited.connect(_btn_hover.bind(start_button, false))
	if encyclopedia_button:
		encyclopedia_button.pressed.connect(_on_encyclopedia_pressed)
		encyclopedia_button.mouse_entered.connect(_btn_hover.bind(encyclopedia_button, true))
		encyclopedia_button.mouse_exited.connect(_btn_hover.bind(encyclopedia_button, false))
	if close_btn:
		close_btn.pressed.connect(_close_encyclopedia)
	
	if enc_overlay:
		enc_overlay.visible = false
	
	_build_encyclopedia()
	
	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager and high_score_label:
		var hs = game_manager.get_high_score()
		if hs > 0:
			high_score_label.text = "最高分: %d" % hs
	
	_animate_title()
	_animate_bg_glow()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept") and not _encyclopedia_visible:
		_on_start_pressed()
	if Input.is_action_just_pressed("ui_cancel") and _encyclopedia_visible:
		_close_encyclopedia()

func _animate_title():
	if not title_label:
		return
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate:a", 0.8, 1.8)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.8)

func _animate_bg_glow():
	if not bg_glow:
		return
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(bg_glow, "color", Color(0.14, 0.09, 0.32, 0.5), 3.0)
	tween.tween_property(bg_glow, "color", Color(0.10, 0.06, 0.24, 0.35), 3.0)

func _btn_hover(btn: Button, entering: bool):
	if not btn:
		return
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	if entering:
		tween.tween_property(btn, "modulate", Color(1.15, 1.15, 1.15, 1), 0.2)
	else:
		tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.15)

func _on_start_pressed():
	start_game.emit()

func _on_encyclopedia_pressed():
	_open_encyclopedia()

func _open_encyclopedia():
	_encyclopedia_visible = true
	if main_container:
		main_container.visible = false
	if enc_overlay:
		enc_overlay.visible = true

func _close_encyclopedia():
	_encyclopedia_visible = false
	if enc_overlay:
		enc_overlay.visible = false
	if main_container:
		main_container.visible = true

func _build_encyclopedia():
	if not card_list:
		return
	
	for child in card_list.get_children():
		child.queue_free()
	
	var categories := {
		"防御/护盾类": ["score_shield", "mirror_shield", "satellite", "phantom_cloak", "phoenix_reborn", "last_stand", "wall_phase"],
		"攻击/清障类": ["time_bomb", "ricochet_dart", "yoyo", "fire_nova", "revenge_spirit"],
		"移动/位移类": ["charged_jump", "swap", "auto_dodge"],
		"主动技能类": ["decoy", "time_slow"],
		"碰撞体/体积类": ["soft_kneepads", "lucky_rabbit_foot"],
		"得分/经济类": ["score_pouch", "magnet_gloves", "coin_bonus"],
		"生命类": ["spare_life", "fast_recovery"],
		"挑战/加成类": ["flawless_challenge"]
	}
	
	for category_name in categories:
		var ability_ids: Array = categories[category_name]
		
		var cat_label = Label.new()
		cat_label.text = "【%s】(%d)" % [category_name, ability_ids.size()]
		cat_label.add_theme_font_size_override("font_size", 18)
		cat_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.8, 1.0))
		card_list.add_child(cat_label)
		
		for ability_id in ability_ids:
			var ability = AbilityManager.get_ability_resource(ability_id)
			if not ability:
				continue
			
			var row = _make_row(ability)
			card_list.add_child(row)
		
		card_list.add_child(Control.new())
	
	var footer = Label.new()
	footer.text = "共 %d 张卡牌 · ESC关闭" % AbilityManager.get_all_ability_resources().size()
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(0.35, 0.38, 0.48, 0.7))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_list.add_child(footer)

	_build_obstacle_encyclopedia()

func _make_row(ability: AbilityData) -> HBoxContainer:
	var rarity_color = _get_rarity_color(ability.rarity)
	var rarity_text = _get_rarity_text(ability.rarity)
	
	var outer = HBoxContainer.new()
	outer.custom_minimum_size.y = 56
	
	var color_bar = ColorRect.new()
	color_bar.custom_minimum_size = Vector2(4, 54)
	color_bar.color = rarity_color * Color(0.65, 0.65, 0.72, 1.0)
	color_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	outer.add_child(color_bar)
	
	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 3)
	outer.add_child(inner)
	
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	inner.add_child(top_row)
	
	var name_lbl = Label.new()
	name_lbl.text = ability.display_name
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", rarity_color.lightened(0.18))
	top_row.add_child(name_lbl)
	
	var tag = Label.new()
	tag.text = "[%s]" % rarity_text
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", rarity_color.darkened(0.22))
	top_row.add_child(tag)
	
	var stack_tag = Label.new()
	if ability.stackable:
		stack_tag.text = " 可叠加(%d)" % ability.max_stacks
	else:
		stack_tag.text = " 不可叠加"
	stack_tag.add_theme_font_size_override("font_size", 12)
	stack_tag.add_theme_color_override("font_color", Color(0.45, 0.48, 0.58, 0.8))
	top_row.add_child(stack_tag)
	
	var desc_lbl = Label.new()
	desc_lbl.text = "  " + ability.description
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.77, 0.86, 0.95))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(desc_lbl)
	
	return outer

func _build_obstacle_encyclopedia():
	if not card_list:
		return
	
	var sep = HSeparator.new()
	card_list.add_child(sep)
	
	var section_title = Label.new()
	section_title.text = "═══ 障碍物图鉴 ═══"
	section_title.add_theme_font_size_override("font_size", 22)
	section_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15, 1))
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_list.add_child(section_title)
	
	var obstacles := [
		{
			"name": "普通障碍物",
			"color": Color(0.85, 0.35, 0.3),
			"desc": "最常见的障碍物，随机颜色，旋转下落。碰撞玩家造成1点伤害。",
			"trigger": "基础生成",
			"affects": "- 可被弹射球/反弹镖/火环摧毁\n- 可被反射\n- 可被时间减速\n- 能量护盾冲击波清除\n- 诱饵吸引\n- 卫星碰撞消除",
		},
		{
			"name": "能量核心",
			"color": Color(1.0, 0.2, 0.15),
			"desc": "红色发光球体，带脉冲特效。被攻击技能（弹射球/反弹镖/火环）摧毁时会爆炸，清除同轨道上所有障碍物。",
			"trigger": "独立于普通障碍物生成",
			"affects": "- 被技能摧毁时触发范围爆炸清障\n- 直接碰撞仍扣血\n- 时间减速有效\n- 需先被技能击杀才能清除",
		},
		{
			"name": "大块头",
			"color": Color(0.6, 0.45, 0.25),
			"desc": "占据两个车道的巨型方块。体积大更难躲避，但出现频率低且有冷却时间。",
			"trigger": "有冷却时间，连续不超过3个同类型",
			"affects": "- 跨两车道，走位受限时威胁大\n- 其他与普通障碍物相同",
		},
		{
			"name": "穿刺者（精英）",
			"color": Color(1.0, 0.35, 0.05),
			"desc": "橙色竖长条形精英障碍物。能穿透幻影斗篷、能量护盾、镜之盾、复仇之魂的防御判定，直接扣除生命值。是后期唯一能打破「不死之身」的威胁。",
			"trigger": "难度≥4.0后开始出现，难度越高概率越大",
			"affects": "- 跳过能量护盾、镜之盾、幻影斗篷的免伤判定\n- 直接扣血（但复仇之魂、凤凰、最后一搏仍然生效）\n- 被攻击技能正常摧毁",
		}
	]
	
	for obs in obstacles:
		var row = _make_obstacle_row(obs)
		card_list.add_child(row)
		card_list.add_child(Control.new())
	
	var obs_footer = Label.new()
	obs_footer.text = "共 %d 种障碍物 · 难度越高精英越多" % obstacles.size()
	obs_footer.add_theme_font_size_override("font_size", 13)
	obs_footer.add_theme_color_override("font_color", Color(0.35, 0.38, 0.48, 0.7))
	obs_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_list.add_child(obs_footer)

func _make_obstacle_row(obs: Dictionary) -> VBoxContainer:
	var outer = VBoxContainer.new()
	outer.custom_minimum_size.y = 20
	outer.add_theme_constant_override("separation", 4)
	
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	outer.add_child(top_row)
	
	var color_dot = ColorRect.new()
	color_dot.custom_minimum_size = Vector2(16, 16)
	color_dot.color = obs["color"]
	color_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(color_dot)
	
	var name_lbl = Label.new()
	name_lbl.text = obs["name"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", obs["color"].lightened(0.15))
	top_row.add_child(name_lbl)
	
	var fields := [
		["描述", obs["desc"]],
		["触发条件", obs["trigger"]],
		["受影响情况", obs["affects"]]
	]
	
	for field in fields:
		var lines = field[1].split("\n")
		for i in range(lines.size()):
			var prefix = "  ▸ %s: " % field[0] if i == 0 else "           "
			var field_label = Label.new()
			field_label.text = prefix + lines[i]
			field_label.add_theme_font_size_override("font_size", 14)
			field_label.add_theme_color_override("font_color", Color(0.72, 0.74, 0.84, 0.92))
			field_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			outer.add_child(field_label)
	
	return outer

func _get_rarity_text(rarity: int) -> String:
	match rarity:
		0: return "普通"
		1: return "稀有"
		2: return "史诗"
		3: return "传说"
	return "未知"

func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color(0.82, 0.84, 0.88)
		1: return Color(0.35, 0.62, 1.0)
		2: return Color(0.72, 0.35, 1.0)
		3: return Color(1.0, 0.78, 0.22)
	return Color(1, 1, 1)
