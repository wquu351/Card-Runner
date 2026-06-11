# FishGameLite 批量修复与能力替换计划（第二批）

## 仓库研究结论

- `player.gd` 当前约 1211 行，包含所有能力逻辑
- 障碍物 `obstacle.gd` 使用 `speed_multiplier` 和 `ability_speed_mult` 控制速度
- `GameFlowManager.request_card_selection()` 已有空数组检查，但 `upgrade_trigger` 仍会持续触发
- 玩家碰撞体为 `CharacterBody2D`，Godot 4 支持 `motion_mode` 和 `safe_margin` 属性
- `obstacle.gd` 是 `Area2D`，不是物理体，碰撞检测在 `_on_body_entered` 回调中

---

## 问题6：修复触壁瞬移 Bug

### 分析
当前 `wall_phase` 逻辑在 `_physics_process` 中检测 `position.x < -PLAYER_SIZE / 2` 或 `> screen_width + PLAYER_SIZE / 2`，但玩家位置被车道系统 `LANE_POSITIONS` 限制在 `[240, 360, 480]` 范围内，永远不会超出屏幕边界，因此触壁瞬移永远不会触发。

### 修复方案
- 修改 `wall_phase` 逻辑：当玩家在车道 0 按左移、或在车道 2 按右移时，触发瞬移到对面车道
- 车道 0 按左 → 瞬移到车道 2，车道 2 按右 → 瞬移到车道 0
- 瞬移时给予短暂无敌

### 涉及文件
- `player.gd` — 修改 wall_phase 逻辑和车道切换逻辑

---

## 问题7：火焰足迹 → 定时炸弹（time_bomb）

### 涉及文件
1. **删除** `abilities/data/flame_trail.tres`
2. **新建** `abilities/data/time_bomb.tres`
3. **新建** `time_bomb.gd` — 炸弹节点脚本
4. **新建** `time_bomb.tscn` — 炸弹场景
5. **修改** `player.gd` — 移除火焰足迹逻辑，新增定时炸弹逻辑
6. **修改** `texture_generator.gd` — 新增炸弹纹理

### 步骤
- 删除 `flame_trail.tres`，新建 `time_bomb.tres`（rarity=1 RARE, stackable=false, TRIGGER类型）
- 新建 `time_bomb.gd`：炸弹在放置后 2 秒爆炸，播放膨胀+闪光动画，检测大范围（200px）内障碍物并摧毁
- 新建 `time_bomb.tscn`：Area2D + Sprite2D + CollisionShape2D
- player.gd：移除 `fire_trail_*` 变量和逻辑，新增 `time_bomb_enabled`、`time_bomb_timer`(10秒)、`time_bomb_scene`
- 新增 `_check_time_bomb_ability()` 和定时器逻辑

---

## 问题8：高速移动碰撞穿透修复

### 分析
玩家是 `CharacterBody2D`，使用 `move_and_slide()`。Godot 4 的 `CharacterBody2D` 默认使用离散碰撞检测。高速移动时可能穿过障碍物。

### 修复方案
- 在 `_ready()` 中设置 `collision_shape` 的 `debug_color` 不影响碰撞，但可设置 `safe_margin` 增大
- 在 `CharacterBody2D` 上设置 `safe_margin = 8.0`（默认 1px）
- 添加射线检测：在高速移动时（sprint_active），每帧发射射线检测前方障碍物

### 涉及文件
- `player.gd` — 增大 safe_margin，添加射线检测

---

## 问题9：溜溜球改为一次只击败一个障碍物

### 修改方案
- 修改 `_fire_yoyo_projectile()` 中的碰撞回调
- 飞行物碰到第一个障碍物后立即销毁自身（`projectile.queue_free()`）
- 冷却时间保持 1.5 秒不变

### 涉及文件
- `player.gd` — 修改 `_on_yoyo_hit_obstacle` 和 `_fire_yoyo_projectile`

---

## 问题10：残影步 → 能量护盾（energy_shield）

### 涉及文件
1. **删除** `abilities/data/phantom_dash.tres`
2. **新建** `abilities/data/energy_shield.tres`
3. **修改** `player.gd` — 移除残影步逻辑，新增能量护盾逻辑

### 步骤
- 删除 `phantom_dash.tres`，新建 `energy_shield.tres`（rarity=2 EPIC, stackable=false, TRIGGER类型）
- player.gd：移除 `phantom_dash_*` 变量和逻辑，新增 `energy_shield_enabled`、`shield_count`(护盾层数)
- 修改 `take_hit()`：优先消耗护盾层数，每层抵挡一次伤害
- 护盾视觉：当有护盾时，玩家周围显示护盾光环

---

## 问题11：沉稳之躯 → 得分护盾

### 涉及文件
1. **修改** `abilities/data/steady_body.tres` → 改为得分护盾
2. **修改** `player.gd` — 移除旧沉稳之躯逻辑，新增得分护盾逻辑
3. **修改** `game_manager.gd` — 添加得分事件信号

### 步骤
- 修改 `steady_body.tres`：ability_id="score_shield", display_name="得分护盾", description="获得护盾，每100分触发一次，抵挡伤害并释放冲击波", rarity=1 RARE, stackable=true, max_stacks=3, TRIGGER类型
- player.gd：新增 `score_shield_enabled`、`score_shield_energy`(0.0)、`score_shield_threshold`(100)、`score_shield_ready`(bool)
- 连接 GameManager 的得分信号，每获得分数时积累能量
- 能量满时 score_shield_ready=true，下次受击时消耗护盾抵挡伤害并释放冲击波
- 每层叠加减少 threshold（100/80/60）

---

## 问题12：障碍物减速剂 → 落地缓冲（landing_buffer）

### 涉及文件
1. **删除** `abilities/data/obstacle_slow.tres`
2. **新建** `abilities/data/landing_buffer.tres`
3. **修改** `player.gd` — 新增落地缓冲逻辑
4. **修改** `obstacle.gd` — 新增停滞/恢复机制

### 步骤
- 删除 `obstacle_slow.tres`，新建 `landing_buffer.tres`（rarity=0 COMMON, stackable=true, max_stacks=3, TRIGGER类型）
- player.gd：新增 `landing_buffer_enabled`，在着陆检测时触发
- obstacle.gd：新增 `freeze_timer` 变量和停滞逻辑，当 `freeze_timer > 0` 时不移动
- 落地时遍历所有障碍物，设置 `freeze_timer = 0.5 + stacks * 0.25`

---

## 额外修复：后期没牌可选时的问题

### 修改方案
- 修改 `GameFlowManager.request_card_selection()`：当返回空数组时，打印日志并返回 false（已有此逻辑）
- 修改 `upgrade_trigger.gd`：当 `request_card_selection()` 返回 false 时，停止触发器（避免空转）

### 涉及文件
- `systems/upgrade_trigger.gd` — 添加空牌池检测
- `systems/game_flow_manager.gd` — 增强日志输出

---

## 潜在依赖与注意事项

1. **文件重命名**：`steady_body.tres` 需要重命名为 `score_shield.tres`，但 Godot 的 AbilityManager 按文件名加载，直接删除旧文件新建新文件即可
2. **obstacle.gd 修改**：新增 `freeze_timer` 需确保不影响其他能力（如 time_slow）
3. **护盾系统**：energy_shield 和 score_shield 都涉及护盾，需统一护盾计数系统
4. **碰撞修复**：safe_margin 增大可能影响正常移动手感，需适度
5. **try_use_skill()**：移除 phantom_dash 后需从技能优先级中删除

## 风险处理

- **护盾冲突**：avalon 护盾和 energy_shield 护盾共存时，take_hit 优先消耗 energy_shield 层数
- **定时炸弹范围**：200px 范围可能过大，需测试调整
- **落地缓冲与 time_slow 叠加**：两者独立运作，不冲突
