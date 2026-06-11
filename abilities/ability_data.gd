## 能力数据资源：定义单个能力的属性，包括ID、名称、稀有度、叠加性和效果类型
class_name AbilityData
extends Resource

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

enum EffectType {
	MULTIPLY,
	ADD,
	SET,
	TRIGGER
}

@export var ability_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var stackable: bool = false
@export var max_stacks: int = 1
@export var effect_type: EffectType = EffectType.ADD
@export var target_attribute: String = ""
@export var effect_value: float = 1.0
@export var shortcut_key: String = ""
@export var auto_release: bool = false
