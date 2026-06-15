# PlaneShooter (Godot 4) — 项目说明 / 跨机器协作上下文

> 这是 Unity 版 PlaneShooter 的 **Godot 4 + GDScript 完整复刻**。
> Unity 原版在 `F:\Projects\unity_projects\plane_shooting_game_2d\PlaneShooter`(C#)。
> 本仓库每完成一块有意义的工作都会更新本文件,供另一台机器拉取后无缝接上进度。

## 引擎 / 配置
- **Godot 4.3+,GDScript**(原版是 C#;本次按用户要求用 GDScript)。
- 竖屏移动端:viewport 720x1280,stretch=canvas_items/keep,handheld orientation=portrait。
- `project.godot` 已开启 `emulate_touch_from_mouse` / `emulate_mouse_from_touch`,编辑器里用鼠标即可测试触屏拖动。
- **Autoload 单例:** `GameManager`(`res://scripts/system/GameManager.gd`)。
- **主场景:** `res://scenes/Main.tscn`。
- **碰撞层命名(layer_names/2d_physics):** 1=player,2=player_bullet,3=enemy。

## 目录结构
```
scripts/
  system/  GameManager.gd(autoload 单例)、Main.gd(主场景根,_ready 里 reset)
  player/  Player.gd、PlayerHealth.gd、Bullet.gd
  enemy/   Enemy.gd、EnemySpawner.gd
  ui/      GameHUD.gd
scenes/
  Main.tscn(根:Background + Player + EnemySpawner + GameHUD)
  Player.tscn、Bullet.tscn、Enemy.tscn、GameHUD.tscn
icon.svg(占位图标)
```

## 已实现(对齐 Unity 阶段 1–6)
- **Player.gd**(Area2D):触屏/鼠标拖动跟随(lerp 平滑)、屏幕边界 Clamp、移动端自动持续开火(fire_rate)。子弹实例化加到 current_scene,从 Muzzle 发射。
- **PlayerHealth.gd**(Player 子节点 Node2D):血量、**无敌帧 + 闪烁**(切 Sprite.visible)、`take_damage()`、死亡时 `GameManager.trigger_game_over()` 并隐藏/停用玩家。`_ready` 上报初始血量给 HUD。
- **Bullet.gd**(Area2D):`launch(dir, speed)` 设方向,向上飞,命中(area/body_entered → `take_damage`)或出屏/超时回收(queue_free)。
- **Enemy.gd**(Area2D):向下移动、血量/`take_damage`/`die`、出屏回收;`die()` 调 `GameManager.add_score(score_value)`;撞玩家时给 PlayerHealth 造成 contact_damage。
- **EnemySpawner.gd**(Node2D):计时器累加(替代 Unity 协程),定时顶部随机 X 刷怪,仅在 PLAYING 状态刷。
- **GameManager.gd**(autoload):状态枚举 PLAYING/GAME_OVER、score、`add_score`、`report_health`、`trigger_game_over`、`restart_game`(reload_current_scene)、`reset`。用 **signal**(score_changed / health_changed / game_over / game_restarted)解耦 HUD —— 对应 Unity 的事件订阅。
- **GameHUD.gd**(CanvasLayer):订阅 GameManager 信号刷新分数/血量;GameOver 面板 + RESTART 按钮(调 `restart_game`)。

## 架构约定 / 与 Unity 的差异
- 碰撞用 Area2D + area_entered/body_entered(对应 Unity OnTriggerEnter2D)。
- **暂未做对象池**:Godot 无内置 ObjectPool,当前子弹/敌机命中或出屏即 `queue_free()`。Bullet/Enemy 的接口(launch、出屏回收)已为后续接池留好。若性能需要可再加。
- 重开走 `reload_current_scene`,Main._ready 调 `GameManager.reset()` 归零。

## 待办(对齐 Unity 后续阶段)
- 已全部追平 Unity 阶段 7-9(见下)。剩余可选项:子弹/敌机对象池(当前命中/出屏即 queue_free);更精细的美术/动画;Game Over/Victory 时是否冻结全场(当前仅停止刷怪+隐藏玩家,敌机/子弹仍在背景移动)。

## 阶段 7-9(2026-06-15 补齐,追平 Unity)
**美术/音效(程序生成,无外部素材):**
- `tools/gen_pixel_art.py` 生成像素图到 `assets/art/`:player_0/1、enemy_0、bullet、enemy_bullet、explosion_0..6(7帧)、boss_body、boss_gun_main/sub、stars。
- `tools/gen_sfx.py` 用 numpy 合成 wav 到 `assets/sfx/`:shoot/explosion/hit/victory。
- 像素风:project.godot 设 `rendering/textures/canvas_textures/default_texture_filter=0`(Nearest)。

**阶段7 特效(autoload + 助手):**
- `SfxManager`(autoload):AudioStreamPlayer 池,play_shoot/explosion/hit/victory。
- `ExplosionManager`(autoload):spawn_at(pos, scale) 实例化 `Explosion.tscn`。`Explosion.gd` 运行时逐帧换贴图(7帧 @0.05s)播完自销。
- `SpriteFlash`(挂敌机/Boss部位下):给 Sprite2D 套 `assets/shaders/flash.gdshader`(白闪),flash() 触发。
- `ScrollingBackground`:Sprite2D + region_rect 偏移做无缝纵向滚动(texture_repeat=ENABLED)。
- `PlayerBanking`:按水平速度让玩家 Sprite 倾斜。

**阶段8 关卡波次:**
- `LevelData`(extends Resource,class_name)= level_name + waves[WaveData] + boss_scene;`WaveData` = enemy_count/spawn_interval/delay_after_clear/enemy_override。复刻 Unity ScriptableObject,关卡资产在 `levels/*.tres`。
- `EnemySpawner` 重写:用 await/计时跑 campaign。每关「第X关」横幅 → 逐波刷怪(**整波击毁才过波**,靠 Enemy.set_on_returned 回调计数)→ 可选 Boss(「警告!Boss来袭」)→「第X关通过」→ 下一关 → 全清 trigger_victory。
- `GameManager` 加 VICTORY 状态 + victory/banner_requested 信号;HUD 加横幅 Label + Victory 面板。
- `Enemy` 加 set_on_returned/_return():离场(死亡/出屏/撞玩家)只回调一次。
- 关卡配置:`levels/level1.tres`(3波无Boss)、`level2.tres`(2波+TankBoss);Main.tscn 的 EnemySpawner.levels 引用二者。

**阶段9 坦克 Boss:**
- `EnemyBullet`(Area2D,layer4/mask1):launch(dir) 朝玩家飞,命中玩家扣血,出屏回收。`EnemyBullet.tscn`。
- `BossPart`(Area2D,layer4):可破坏炮台,take_damage+闪白+运行时 ColorRect 头顶血条,破了回调 Boss。`BossPart.tscn`。
- `TankBoss`(Node2D):进场→上半屏徘徊+正弦起伏;主炮(parts[0])用 await 跑「3单发→停→扇形齐射→停」循环,副炮(parts[1..])定时瞄准玩家单发;全部 parts 破→计分+多处爆炸+回调 spawner。`TankBoss.tscn`(车体 Body + MainGun + SubGunL/R)。
- Boss 找玩家靠 "player" 组(Player._ready 里 add_to_group)。spawner 用 boss.init_boss(回调) 等待击杀。

## 碰撞层
- 1=player,2=player_bullet,3(=1+2 的 mask 值,非层)。层位:player=layer1,player_bullet=layer2,enemy/boss_part/enemy_bullet=layer4。
- player(layer1,mask4)、player_bullet(layer2,mask4)、enemy(layer4,mask3)、enemy_bullet(layer4,mask1)、boss_part(layer4,mask0)。

## 校验状态
- 本机 VM 无 Godot 可执行文件,**未能跑 `--check-only`**;但用户机 **Godot 4.6.3** 已打开并导入项目:`.godot/global_script_class_cache.cfg` 注册了全部 14 个 class_name 脚本、贴图/音效均已导入,无导入报错。建议运行一局完整验证(2关+Boss+通关)。

## 已知清理项
- 项目根下有个**多余嵌套目录 `PlaneShooter_godot/assets/art/`**(早期脚本路径 bug 残留的重复旧图),未被任何场景引用,可手动删除。VM 内删除受权限限制删不掉。

## 踩坑记录
- **ColorRect 视觉节点的引用类型要用 `CanvasItem`,不能用 `Node2D`。** ColorRect 属 Control→CanvasItem 分支。`visible` 在 CanvasItem 上;换 Sprite2D(属 Node2D)也兼容 CanvasItem。
- **实例化节点先 add_child 再设 global_position**,否则未入树时 global 变换不可靠。spawner/Boss 已按此修正。
- 启动日志 `... low quality OpenGL 3.3 support, switching to ANGLE` 是显卡驱动提示,无害。
- 手写大段文件时注意:单次 Edit/Write 有体积上限,超了会被静默截断,需分块写。


## 2026-06-15 科幻像素风素材重制
- 更新 	ools/gen_pixel_art.py：引入科幻配色(钢铁灰 + 青色/紫色霓虹)与更锋利的轮廓，保持原尺寸/文件名兼容。
- 重新生成 ssets/art/ 下贴图：
  - 玩家帧：player_0.png, player_1.png
  - 敌机：enemy_0.png
  - 子弹：ullet.png, enemy_bullet.png
  - 爆炸序列：explosion_0..6.png
  - Boss：oss_body.png, oss_gun_main.png, oss_gun_sub.png
  - 星域平铺：stars.png
- Godot 打开项目后会自动重新导入 png。
- 如需更贴合新机体外形，可在 scripts/player/Player.gd:18 按需微调 _half_extents。
- 清理建议：根目录内冗余 PlaneShooter_godot/assets/art/ 未被引用，可删除。
