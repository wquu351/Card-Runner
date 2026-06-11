## 技能分类器：定义主动/被动技能，供UI使用
extends Node

enum SkillType {
	ACTIVE,
	PASSIVE
}

const SKILL_DEFINITIONS = {
	"decoy": {
		"type": SkillType.ACTIVE,
		"display_name": "替身假人",
		"icon_text": "替",
		"color": Color(0.6, 0.8, 1.0),
		"glow_color": Color(1.0, 0.85, 0.2),
		"description": "创造假人吸收障碍物"
	},
	"time_slow": {
		"type": SkillType.ACTIVE,
		"display_name": "时间沙漏",
		"icon_text": "时",
		"color": Color(0.4, 0.6, 1.0),
		"glow_color": Color(1.0, 0.85, 0.2),
		"description": "减速所有障碍物3秒"
	},
	"swap": {
		"type": SkillType.ACTIVE,
		"display_name": "换位术",
		"icon_text": "换",
		"color": Color(1.0, 0.5, 1.0),
		"glow_color": Color(1.0, 0.85, 0.2),
		"description": "与障碍物互换位置"
	},
	"ricochet_dart": {
		"type": SkillType.PASSIVE,
		"display_name": "弹射飞镖",
		"icon_text": "弹",
		"color": Color(0.2, 0.9, 0.8),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动发射弹射飞镖"
	},
	"time_bomb": {
		"type": SkillType.PASSIVE,
		"display_name": "定时炸弹",
		"icon_text": "炸",
		"color": Color(0.9, 0.5, 0.2),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动放置定时炸弹"
	},
	"auto_dodge": {
		"type": SkillType.PASSIVE,
		"display_name": "轻盈闪避",
		"icon_text": "闪",
		"color": Color(0.3, 1.0, 0.8),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动闪避障碍物"
	},
	"fire_nova": {
		"type": SkillType.PASSIVE,
		"display_name": "火焰新星",
		"icon_text": "火",
		"color": Color(1.0, 0.4, 0.2),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动释放火焰新星"
	},
	"revenge_spirit": {
		"type": SkillType.PASSIVE,
		"display_name": "复仇之魂",
		"icon_text": "复",
		"color": Color(1.0, 0.2, 0.4),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "护盾消耗发射光柱"
	},
	"phoenix_reborn": {
		"type": SkillType.PASSIVE,
		"display_name": "凤凰涅槃",
		"icon_text": "凤",
		"color": Color(1.0, 0.6, 0.2),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "死亡时复活"
	},
	"phantom_cloak": {
		"type": SkillType.PASSIVE,
		"display_name": "幻影斗篷",
		"icon_text": "幻",
		"color": Color(0.7, 0.4, 1.0),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动虚化穿越障碍"
	},
	"mirror_shield": {
		"type": SkillType.PASSIVE,
		"display_name": "镜之盾",
		"icon_text": "镜",
		"color": Color(0.3, 0.6, 1.0),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动恢复护盾层"
	},
	"score_shield": {
		"type": SkillType.PASSIVE,
		"display_name": "能量护盾",
		"icon_text": "盾",
		"color": Color(1.0, 0.9, 0.2),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动恢复护盾层"
	},
	"yoyo": {
		"type": SkillType.PASSIVE,
		"display_name": "弹射球",
		"icon_text": "球",
		"color": Color(1.0, 0.6, 0.2),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "自动发射弹射球"
	},
	"coin_bonus": {
		"type": SkillType.PASSIVE,
		"display_name": "金币加成",
		"icon_text": "币",
		"color": Color(1.0, 0.85, 0.2),
		"glow_color": Color(0.9, 0.95, 1.0),
		"description": "每收集一个金币，分数倍率永久+0.02"
	}
}

func get_skill_type(skill_id: String) -> SkillType:
	if SKILL_DEFINITIONS.has(skill_id):
		return SKILL_DEFINITIONS[skill_id]["type"]
	return SkillType.PASSIVE

func get_skill_definition(skill_id: String) -> Dictionary:
	if SKILL_DEFINITIONS.has(skill_id):
		return SKILL_DEFINITIONS[skill_id]
	return {}

func get_active_skills() -> Array:
	var result = []
	for skill_id in SKILL_DEFINITIONS:
		if SKILL_DEFINITIONS[skill_id]["type"] == SkillType.ACTIVE:
			result.append(skill_id)
	return result

func get_passive_skills() -> Array:
	var result = []
	for skill_id in SKILL_DEFINITIONS:
		if SKILL_DEFINITIONS[skill_id]["type"] == SkillType.PASSIVE:
			result.append(skill_id)
	return result

func is_active_skill(skill_id: String) -> bool:
	return get_skill_type(skill_id) == SkillType.ACTIVE

func is_passive_skill(skill_id: String) -> bool:
	return get_skill_type(skill_id) == SkillType.PASSIVE
