# Fish Game Lite - 开发者文档

## 项目概述

竖屏跑酷游戏（720x1280），使用 Godot 4.6 + GDScript 开发。玩家左右移动和跳跃躲避从上方掉落的障碍物，每 500 分触发选卡成长系统。

---

## 架构设计

### 三大模块（互不干扰）

```
┌─────────────────────────────────────────────────────────────┐
│                     能力数据层                               │
│  abilities/ability_data.gd + abilities/data/*.tres          │
│  纯数据配置，无逻辑代码                                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                     能力管理器                               │
│  AbilityManager (Autoload)                                   │
│  记录已选能力 / 计算属性修正 / 提供查询接口                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                   选卡流程控制                               │
│  GameFlowManager (Autoload) + UpgradeTrigger (场景节点)       │
│  游戏状态管理 / 触发选卡 / 暂停恢复 / UI 显示                 │
└─────────────────────────────────────────────────────────────┘
```

**核心原则**：新增能力只需新建 .tres 文件放入 abilities/data/，无需修改 UI 和流程代码。

---

## 文件结构

```
fish-game-lite/
├── project.godot                    # 项目配置（含 Autoload 和输入映射）
├── main.gd                          # 主场景脚本（背景纹理生成）
├── main.tscn                        # 主场景（所有游戏节点）
├── player.gd                        # 玩家角色（移动/跳跃/生命/无敌）
├── obstacle.gd                      # 障碍物（下落/旋转/碰撞检测）
├── obstacle_spawner.gd              # 障碍物生成器（难度递增）
├── game_manager.gd                  # 游戏管理器（分数/生命显示/游戏结束）
├── texture_generator.gd             # 纹理生成器（纯代码生成所有视觉素材）
│
├── abilities/                       # 能力系统
│   ├── ability_data.gd              # 能力数据模板（Resource）
│   ├── ability_manager.gd           # 能力管理器（Autoload）
│   └── data/                        # 能力数据文件
│       ├── speed_boost.tres         # 疾跑
│       ├── jump_boost.tres          # 弹跳强化
│       ├── speed_master.tres        # 速度大师
│       ├── extra_jump.tres          # 额外跳跃
│       ├── extra_life.tres          # 额外生命
│       ├── shield.tres              # 护盾
│       └── score_multiply.tres      # 得分翻倍
│
├── systems/                         # 系统模块
│   ├── game_flow_manager.gd         # 游戏流程管理器（Autoload）
│   └── upgrade_trigger.gd           # 选卡触发器（场景节点）
│
└── ui/                              # UI 组件
    ├── ability_hud.gd               # 能力展示面板
    └── card_selection/              # 选卡界面
        ├── card_selection_ui.gd     # 选卡界面管理
        ├── card_selection_ui.tscn
        ├── ability_card.gd          # 单张卡牌组件
        └── ability_card.tscn
```

---

## Autoload 全局单例

| 名称 | 脚本路径 | 职责 |
|------|----------|------|
| TextureGenerator | res://texture_generator.gd | 纯代码生成所有纹理素材 |
| AbilityManager | res://abilities/ability_manager.gd | 管理能力数据和属性修正 |
| GameFlowManager | res://systems/game_flow_manager.gd | 管理游戏状态和选卡流程 |

---

## 场景节点树

```
RunnerGame (Node2D) ← main.gd
├── Background (Sprite2D)          # 深紫色渐变背景
├── ScoreLabel (Label)             # 分数显示
├── LivesLabel (Label)             # 生命值显示
├── AbilityHUD (Control)          # 已选能力列表
│   └── VBoxContainer
├── Player (CharacterBody2D)      ← player.gd
│   ├── Sprite2D
│   └── CollisionShape2D
├── ObstacleSpawner (Node2D)      ← obstacle_spawner.gd
├── GameManager (Node)            ← game_manager.gd
├── UpgradeTrigger (Node)         ← upgrade_trigger.gd
└── CardSelectionUI (CanvasLayer) ← card_selection_ui.gd
    ├── Background (ColorRect)    # 半透明遮罩
    └── PanelContainer            # 选卡面板
        └── MarginContainer
            └── VBoxContainer
                ├── TitleLabel
                └── CardContainer (HBoxContainer)
                    └── AbilityCard x3 (Button)
```

---

## 核心系统详解

### 1. 能力数据模板 (AbilityData)

自定义 Resource，每个能力一个 .tres 文件。

```gdscript
class_name AbilityData
extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum EffectType { MULTIPLY, ADD, SET, TRIGGER }

@export var ability_id: String          # 唯一标识 "speed_boost"
@export var display_name: String        # 显示名称 "疾跑"
@export_multiline var description: String  # 描述文本
@export var icon: Texture2D             # 卡牌图标
@export var rarity: Rarity              # 稀有度
@export var stackable: bool             # 是否可叠加
@export var max_stacks: int             # 最大叠加层数
@export var effect_type: EffectType     # 效果类型
@export var target_attribute: String    # 目标属性名
@export var effect_value: float         # 效果数值
```

#### 效果类型说明

| 类型 | 计算方式 | 示例 |
|------|----------|------|
| MULTIPLY | 属性 *= 值 | 速度 x2.0 |
| ADD | 属性 += 值 | 生命 +1 |
| SET | 属性 = 值 | 直接设置 |
| TRIGGER | 触发特殊效果 | 二段跳等 |

#### 稀有度颜色

| 稀有度 | 颜色 | 出现权重 |
|--------|------|----------|
| COMMON | 灰色 #B3B3B3 | 高 |
| RARE | 蓝色 #4D99FF | 中 |
| EPIC | 紫色 #B34DFF | 低 |
| LEGENDARY | 金色 #FFCC33 | 极低 |

---

### 2. 能力管理器 (AbilityManager)

全局 Autoload，负责记录已选能力和计算属性修正。

#### 核心 API

```gdscript
# 添加能力（选卡后调用）
AbilityManager.add_ability("speed_boost") -> bool

# 查询属性最终值（玩家脚本调用）
var speed = AbilityManager.get_attribute_value("move_speed", 400.0)
# 返回：基础值 + 加法修正 * 乘法修正

# 检查能力
AbilityManager.has_ability("speed_boost") -> bool
AbilityManager.get_ability_stacks("speed_boost") -> int

# 获取能力资源
AbilityManager.get_ability_resource("speed_boost") -> AbilityData
AbilityManager.get_all_ability_resources() -> Dictionary

# 重置（游戏重新开始时调用）
AbilityManager.reset()
```

#### 信号

```gdscript
signal ability_added(ability: AbilityData, current_stacks: int)
signal ability_stack_changed(ability_id: String, new_stacks: int)
signal attribute_changed(attribute_name: String, new_value: float)
```

#### 内部数据结构

```gdscript
var owned_abilities: Dictionary = {}      # {ability_id: stack_count}
var _multiply_modifiers: Dictionary = {}   # {attribute: multiplier}
var _add_modifiers: Dictionary = {}        # {attribute: add_value}
```

#### 属性计算公式

```
最终值 = (基础值 + 加法修正) * 乘法修正
```

---

### 3. 游戏流程管理器 (GameFlowManager)

全局 Autoload，管理游戏状态和选卡流程。

#### 游戏状态

```gdscript
enum GameState {
    PLAYING,          # 正常游玩
    SELECTING_CARD,   # 选卡中（游戏暂停）
    PAUSED,           # 暂停
    GAME_OVER         # 游戏结束
}
```

#### 核心 API

```gdscript
# 请求进入选卡
GameFlowManager.request_card_selection() -> bool

# 完成选卡（UI 调用）
GameFlowManager.complete_card_selection("speed_boost") -> bool

# 状态查询
GameFlowManager.is_playing() -> bool
GameFlowManager.is_selecting_card() -> bool

# 配置
GameFlowManager.set_cards_count(3)  # 每次选几张卡

# 重置
GameFlowManager.reset()
```

#### 信号

```gdscript
signal state_changed(new_state: GameState)
signal card_selection_started(available_cards: Array)
signal card_selection_completed(selected_ability: AbilityData)
```

#### 抽卡逻辑

1. 从能力池中筛选可用能力（排除已达上限的）
2. 随机抽取 N 张（默认 3 张）
3. 不可叠加且已拥有的能力会被排除
4. 可叠加但已达最大层数的也会被排除

---

### 4. 选卡触发器 (UpgradeTrigger)

场景节点，挂载在主场景中，负责决定何时触发选卡。

#### 触发方式

| 类型 | 枚举值 | 说明 | 配置参数 |
|------|--------|------|----------|
| TIMER | 0 | 计时器触发 | timer_interval = 15.0 秒 |
| SCORE | 1 | 分数触发 | score_threshold = 500 分 |
| OBSTACLE_COUNT | 2 | 障碍物计数 | obstacle_count_threshold = 10 个 |

#### 当前配置

```
trigger_type = SCORE
score_threshold = 500
```

#### 切换触发方式

```gdscript
# 编辑器中修改 UpgradeTrigger 节点的导出属性
# 或代码修改：
upgrade_trigger.set_trigger_type(UpgradeTrigger.TriggerType.TIMER)
upgrade_trigger.set_timer_interval(20.0)
```

---

### 5. 玩家系统 (Player)

#### 属性与能力联动

```gdscript
# 每帧从 AbilityManager 获取修正后的属性值
var current_speed = AbilityManager.get_attribute_value("move_speed", BASE_SPEED)
var current_jump = AbilityManager.get_attribute_value("jump_force", BASE_JUMP_FORCE)
var jump_add = AbilityManager.get_attribute_value("jump_force_add", 0.0)
```

#### 生命系统

```gdscript
# 碰撞时调用
func take_hit() -> bool:
    if invincible: return false   # 无敌中忽略
    lives -= 1
    if lives <= 0: return true    # 死亡
    # 进入无敌状态（闪烁效果）
    invincible = true
    invincible_timer = base_invincible_time + AbilityManager.get_attribute_value("invincible_time_add", 0.0)
    return false
```

#### 无敌闪烁效果

```gdscript
# 使用 sin 函数实现闪烁
var flash = sin(invincible_timer * 20.0) * 0.5 + 0.5
modulate = Color(1, 1, 1, flash)
```

---

### 6. 障碍物系统

#### 难度递增

```gdscript
# obstacle_spawner.gd
difficulty += delta * 0.05                    # 每秒增加 0.05
next_spawn_time = randf_range(0.8, 1.5) / difficulty  # 生成间隔缩短
speed_multiplier = 1.0 + (difficulty - 1.0) * 0.3     # 速度增加
```

#### 碰撞检测

```gdscript
# obstacle.gd - _on_body_entered
var is_dead = body.take_hit()
if is_dead:
    game_manager.game_over()    # 生命耗尽，游戏结束
else:
    queue_free()                # 障碍物销毁，玩家进入无敌
```

---

### 7. 选卡 UI 系统

#### CardSelectionUI

全屏 CanvasLayer，游戏暂停时仍可交互。

```
工作流程：
1. 监听 GameFlowManager.card_selection_started 信号
2. 清空旧卡牌
3. 为每个能力实例化 AbilityCard
4. 连接 card_clicked 信号
5. 点击后调用 GameFlowManager.complete_card_selection()
```

#### AbilityCard

单张卡牌组件（Button），只负责展示和上报点击。

```
构成：Button > VBoxContainer > IconRect + NameLabel + DescLabel + RarityLabel + StacksLabel

功能：
- setup(data: AbilityData)    # 接收数据，自动设置显示
- card_clicked 信号           # 点击时发出 ability_id
- 无图标时自动生成圆形图标     # 根据稀有度颜色
- 悬停放大 1.08 倍            # Tween 动画
- 边框颜色跟随稀有度           # StyleBoxFlat
```

#### AbilityHUD

左上角显示已选能力列表，带入场动画。

---

## 输入映射

| 动作 | 按键 |
|------|------|
| move_left | A / ← |
| move_right | D / → |
| jump | W / ↑ / 空格 |

---

## 已有能力一览

| ID | 名称 | 稀有度 | 类型 | 目标属性 | 数值 | 可叠加 |
|----|------|--------|------|----------|------|--------|
| speed_boost | 疾跑 | 普通 | ADD | move_speed | 0.2 | 是 (5层) |
| jump_boost | 弹跳强化 | 稀有 | ADD | jump_force | 0.15 | 是 (3层) |
| speed_master | 速度大师 | 传说 | MULTIPLY | move_speed | 2.0 | 否 |
| extra_jump | 额外跳跃 | 普通 | ADD | jump_force_add | 100.0 | 是 (10层) |
| extra_life | 额外生命 | 史诗 | ADD | max_lives | 1.0 | 是 (5层) |
| shield | 护盾 | 稀有 | ADD | invincible_time_add | 0.5 | 是 (5层) |
| score_multiply | 得分翻倍 | 传说 | MULTIPLY | score_multiplier | 2.0 | 否 |

---

## 扩展指南

### 新增能力

1. 在 `abilities/data/` 下新建 .tres 文件
2. 选择 AbilityData 脚本
3. 填写字段并保存
4. 完成！AbilityManager 会自动加载

```
无需修改：UI代码、流程代码、玩家代码
```

### 新增触发方式

1. 在 `upgrade_trigger.gd` 的 `TriggerType` 枚举中添加新类型
2. 实现 `_setup_xxx_trigger()` 和对应的检测逻辑
3. 在编辑器中选择新类型

### 新增效果类型

1. 在 `ability_data.gd` 的 `EffectType` 枚举中添加新类型
2. 在 `ability_manager.gd` 的 `_apply_ability_effect()` 中添加处理分支
3. 在玩家脚本中监听 `ability_added` 信号处理特殊效果

### 修改选卡数量

```gdscript
# game_manager.gd _ready()
GameFlowManager.set_cards_count(5)  # 改为五选一
```

### 修改触发频率

```
# 编辑器中修改 UpgradeTrigger 节点
score_threshold = 300  # 更频繁
```

---

## 游戏流程图

```
开始游戏
  │
  ▼
正常游玩 ◄────────────────────────┐
  │                                │
  │ 分数达到 500                    │
  ▼                                │
游戏暂停                            │
  │                                │
  ▼                                │
弹出 3 张卡牌                       │
  │                                │
  ▼                                │
玩家选择一张                        │
  │                                │
  ▼                                │
能力生效（AbilityManager.add_ability）
  │                                │
  ▼                                │
游戏恢复 ──────────────────────────┘
  │
  │ 碰撞障碍物
  ▼
take_hit()
  │
  ├─ 无敌中 → 忽略
  ├─ 有生命 → 生命-1，进入无敌，继续
  └─ 生命=0 → 游戏结束
                  │
                  ▼
              弹出结算窗口
                  │
                  ▼
              重新开始（重置所有系统）
```
