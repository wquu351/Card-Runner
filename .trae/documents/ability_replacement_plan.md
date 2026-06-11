# FishGameLite 能力替换与特效增强计划

## 仓库研究结论

- 项目为 Godot 4.6 的 2D 跑酷游戏，使用 GDScript
- 玩家脚本 `player.gd` 约 1090 行，包含所有能力逻辑（内联式设计）
- 能力数据文件位于 `abilities/data/` 目录，格式为 `.tres` 资源文件
- 能力管理器 `AbilityManager` 为自动加载单例，从 `abilities/data/` 目录自动加载所有 `.tres`
- `GameFlowManager` 的 `ability_pool` 从 `AbilityManager.get_all_ability_resources()` 获取，即自动包含 `abilities/data/` 下所有能力
- 障碍物脚本 `obstacle.gd` 中障碍物从上方下落，有 `position.y` 和 `position.x` 属性
- 玩家有三条车道 `[240, 360, 480]`，移动通过车道切换实现
- `TextureGenerator` 提供程序化纹理生成
- 现有 `shockwave.tscn` / `fire_trail.tscn` 等为独立场景，用于能力特效

---

## 修改一：磁力靴 → 轻盈闪避（auto_dodge）

### 涉及文件
1. **删除** `abilities/data/magnetic_boots.tres`
2. **新建** `abilities/data/auto_dodge.tres`
3. **修改** `player.gd` — 移除磁力靴逻辑，新增自动闪避逻辑

### 步骤

#### 1. 替换能力数据文件
- 删除 `abilities/data/magnetic_boots.tres`
- 新建 `abilities/data/auto_dodge.tres`，内容：
  ```
  ability_id = "auto_dodge"
  display_name = "轻盈闪避"
  description = "附近有障碍物即将落地时，角色自动微小侧向位移躲避（内置冷却）"
  rarity = 1 (RARE)
  stackable = false
  max_stacks = 1
  effect_type = 3 (TRIGGER)
  target_attribute = "auto_dodge"
  effect_value = 0.0
  ```

#### 2. 修改 player.gd
- **移除**磁力靴相关变量（第 70-73 行）：
  - `magnetic_boots_enabled`, `magnetic_boots_vertical_speed`, `magnetic_boots_return_speed`, `screen_top`
- **移除** `_check_magnetic_boots_ability()` 函数
- **移除** `_ready()` 和 `_on_ability_added()` 中对 `_check_magnetic_boots_ability()` 的调用
- **移除** `_physics_process()` 中磁力靴相关逻辑（第 302-316 行的垂直移动和第 355-356 行的 Y 轴限制）
- **新增**自动闪避变量：
  ```gdscript
  var auto_dodge_enabled: bool = false
  var auto_dodge_cooldown: float = 2.0
  var auto_dodge_cooldown_timer: float = 0.0
  var auto_dodge_distance: float = 80.0
  var auto_dodge_detect_range_y: float = 200.0
  var auto_dodge_detect_range_x: float = 100.0
  ```
- **新增** `_check_auto_dodge_ability()` 函数
- **新增** `_process_auto_dodge()` 函数，逻辑：
  - 冷却计时器递减
  - 获取场景中所有障碍物
  - 检测是否有障碍物在玩家 X 范围内且 Y 距离地面小于 `detect_range_y`
  - 若检测到且冷却完成，自动向左或右闪避一小段距离
  - 闪避时短暂无敌（0.1秒）并播放视觉特效
- **修改**车道限制逻辑：闪避后需重新对齐到最近车道

---

## 修改二：移动特效增强

### 涉及文件
1. **修改** `player.gd` — 增强移动视觉反馈
2. **修改** `texture_generator.gd` — 新增拖尾纹理生成函数（可选）

### 步骤

#### 1. 增强现有拖尾粒子
当前 `spawn_trail_particle()` 仅在 `abs(velocity.x) > 0` 时生成简单粒子。改进：
- **车道切换时**生成更明显的残影效果（afterimage）
- **跳跃时**生成扩散粒子
- **着陆时**生成冲击粒子

#### 2. 新增残影系统
- 新增变量 `afterimage_timer` 和 `afterimage_interval`
- 在 `_physics_process()` 中，当玩家正在车道切换（`lane_switching`）时，每隔 `afterimage_interval` 秒生成一个残影
- 残影为 Sprite2D，复制玩家当前位置和外观，快速淡出
- 使用 `TextureGenerator.create_player_texture()` 生成残影纹理

#### 3. 新增跳跃/着陆特效
- 跳跃起飞时：在脚下生成向下扩散的粒子
- 着陆时：在脚下生成向外扩散的环形粒子

---

## 修改三：落地猛击 → 弹射飞镖（ricochet_dart）

### 涉及文件
1. **删除** `abilities/data/ground_slam.tres`
2. **新建** `abilities/data/ricochet_dart.tres`
3. **新建** `ricochet_dart.gd` — 飞镖场景脚本
4. **新建** `ricochet_dart.tscn` — 飞镖场景（可选，也可代码动态创建）
5. **修改** `player.gd` — 移除落地猛击逻辑，新增弹射飞镖逻辑
6. **修改** `texture_generator.gd` — 新增飞镖纹理生成函数

### 步骤

#### 1. 替换能力数据文件
- 删除 `abilities/data/ground_slam.tres`
- 新建 `abilities/data/ricochet_dart.tres`，内容：
  ```
  ability_id = "ricochet_dart"
  display_name = "弹射飞镖"
  description = "每隔6秒自动发射飞镖，在障碍物间弹射，最多摧毁4个"
  rarity = 1 (RARE)
  stackable = false
  max_stacks = 1
  effect_type = 3 (TRIGGER)
  target_attribute = "ricochet_dart"
  effect_value = 0.0
  ```

#### 2. 新增飞镖纹理
在 `texture_generator.gd` 中新增 `create_dart_texture()` 函数：
- 生成三角形/箭头形状纹理
- 颜色：青色/蓝绿色系

#### 3. 新增飞镖场景 `ricochet_dart.tscn` + `ricochet_dart.gd`
飞镖脚本逻辑：
- 继承 `Area2D`
- 属性：`direction`（Vector2）、`speed`（800.0）、`max_bounces`（3）、`current_bounces`（0）、`bounce_range`（200.0）、`lifetime`（3.0）
- `_process()`：沿方向移动，旋转动画
- 超出屏幕或 lifetime 结束后自动销毁
- 碰撞检测：`area_entered` 信号
  - 碰到障碍物：销毁障碍物，`current_bounces += 1`
  - 若 `current_bounces < max_bounces`：搜索 200 像素范围内最近障碍物，改变方向弹射
  - 若无目标或达到弹射上限：继续飞行后消失
- 碰撞特效：命中时生成小型爆炸粒子

#### 4. 修改 player.gd
- **移除**落地猛击相关变量（第 50-54 行）：
  - `ground_pound_enabled`, `jump_start_y`, `was_in_air`, `ground_pound_threshold`, `shockwave_scene`
- **移除** `_check_ground_pound_ability()` 函数
- **移除** `_trigger_ground_pound()` 函数
- **移除** `_ready()` 和 `_on_ability_added()` 中对 `_check_ground_pound_ability()` 的调用
- **移除** `_physics_process()` 中落地猛击相关逻辑（第 320-328 行的落地检测）
- **新增**弹射飞镖变量：
  ```gdscript
  var ricochet_dart_enabled: bool = false
  var ricochet_dart_timer: float = 0.0
  var ricochet_dart_interval: float = 6.0
  var ricochet_dart_scene = preload("res://ricochet_dart.tscn")
  ```
- **新增** `_check_ricochet_dart_ability()` 函数
- **新增** `_process_ricochet_dart()` 函数：6 秒循环计时，触发时寻找最近障碍物方向并发射飞镖
- **新增** `_fire_ricochet_dart()` 函数：实例化飞镖场景，设置初始方向为最近障碍物方向

---

## 潜在依赖与注意事项

1. **GameFlowManager.ability_pool**：当前自动从 `abilities/data/` 加载，删除旧 `.tres` 并新建 `.tres` 后自动生效，无需手动修改 pool
2. **AbilityManager**：同上，自动加载机制保证新能力可用
3. **磁力靴移除后的 Y 轴逻辑**：移除磁力靴后，需确保普通重力逻辑（`else` 分支）仍然完整工作。当前代码中磁力靴和普通重力是 `if/else` 关系，移除磁力靴分支后普通重力逻辑不受影响
4. **落地猛击移除后的跳跃逻辑**：`was_in_air` 和 `jump_start_y` 仅用于落地猛击检测，可安全移除
5. **车道对齐**：自动闪避的横向位移需要考虑车道系统，闪避后应平滑回到最近车道
6. **飞镖弹射**：飞镖使用 `Area2D` 检测碰撞，需确保碰撞层设置正确（`collision_mask = 1`，与障碍物同层）

## 风险处理

- **自动闪避可能过于频繁**：通过 2 秒冷却和检测范围限制控制触发频率
- **飞镖弹射可能找不到目标**：无目标时飞镖直线飞行并在超时后消失
- **残影性能**：限制残影生成频率和数量，使用 `queue_free()` 及时清理
