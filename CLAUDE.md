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

## 美术工作流迁移:程序生成散图 → Aseprite + spritesheet(2026-06-16 起,进行中)
**背景:** 用户接入了 Aseprite MCP,改用 Aseprite 逐像素手绘 + 导出 spritesheet 图集,替代旧的 `gen_pixel_art.py` 程序生成散图。目标是「一个实体一张图集 + 一个 SpriteFrames 资源」,用 `AnimatedSprite2D` 播动画,告别一堆 `_0/_1` 散图。

**Aseprite MCP 环境:**

*旧机器(Windows,已弃用):* MCP 代码 `H:\download\Chrome\aseprite-mcp`;Aseprite 可执行 `H:\...\build\bin\aseprite.exe`。

*当前机器(Intel Mac / macOS,2026-06-17 配好):*
- MCP 代码:`/Users/huoqing/projects/aseprite-mcp`(clone 自 github diivi/aseprite-mcp,包名 `aseprite_mcp`,stdio)。**要求 Python ≥3.13**,用 **uv** 管理(`uv sync` 装依赖,启动 `uv run -m aseprite_mcp`)。系统 Python 3.9 太旧用不了。
- Aseprite 可执行(自编 v1.3.17.2,Skia **m124**,Intel x64):`/Users/huoqing/projects/gitprojects/Aseprite-v1.3.17.2-Source/build/bin/aseprite.app/Contents/MacOS/aseprite`。Skia 预编译包在 `/Users/huoqing/projects/gitprojects/Skia-macOS-Release-x64`(静态链接,运行时已不依赖)。
- `.env` 的 `ASEPRITE_PATH` 指向上面可执行文件。
- 配在 **Cowork**(非经典 Claude Desktop):`~/Library/Application Support/Claude-3p/claude_desktop_config.json` 的 `mcpServers.aseprite`。关键:`command` 用 uv 绝对路径 `/Users/huoqing/.local/bin/uv`(GUI 应用无 shell PATH),`args` 带 `--directory /Users/huoqing/projects/aseprite-mcp`,`env` 里冗余再放一份 `ASEPRITE_PATH`(双保险)。改完须 `Cmd+Q` 彻底重启 Cowork 生效。
- 编译要点(重编时参考):INSTALL.md 钦定 Skia 版本随 Aseprite 版本变(v1.3.17.2→m124,**别按版本新旧猜**);cmake 用 `-DCMAKE_OSX_DEPLOYMENT_TARGET=10.14 -DLAF_BACKEND=skia -DSKIA_DIR/-DSKIA_LIBRARY_DIR(out/Release-x64)/-DSKIA_LIBRARY(libskia.a) -G Ninja`,然后 `ninja aseprite`;产物是 `.app` 包,可执行在 `Contents/MacOS/aseprite`。

**标准流程(每个实体照此办理):**
1. Aseprite 建 16x16(或对应尺寸)`.aseprite`,源文件存 `assets/art/<name>.aseprite`(**源文件要保留**,后续改动靠它)。
2. 多帧逐像素画(`draw_pixels_at` 需带 `layer_name`,默认层名 `"Layer 1"`)。
3. `export_spritesheet` 导出横向图集 `assets/art/<name>.png`,scale=6(与旧素材的 16x16→96px 一致)。
4. 写 `assets/art/<name>_frames.tres`(SpriteFrames,AtlasTexture 按 96px 切帧,定义具名动画 + loop + speed)。
5. 场景里把 `Sprite2D` 换成 `AnimatedSprite2D`,`sprite_frames` 指向 tres,设 `autoplay`。**节点名保持不变**(如玩家仍叫 `Sprite`),这样引用该节点的脚本零改动。
6. 像素清晰度:沿用 project.godot 的 `default_texture_filter=0`(Nearest),图集 `.import` 不必单独设 filter。

**已完成:玩家机(player)**
- 源:`assets/art/player_0.aseprite`(2 帧:短喷焰 / 长喷焰)。图集:`assets/art/player.png`(192x96,横排 2 帧)。资源:`assets/art/player_frames.tres`(动画 `idle`,2帧 loop,speed=10)。
- `Player.tscn`:`Sprite` 节点由 Sprite2D → **AnimatedSprite2D**,autoplay=idle。
- **`PlayerBanking.gd` / `PlayerHealth.gd` 未改**:二者靠 `get_node("Sprite")` 取节点、只用 `rotation_degrees` / `visible`,AnimatedSprite2D 全兼容。用户已在 Godot 验证:动画播放、倾斜、受击闪烁均正常。
- 旧 `player_0.png`/`player_1.png`(+import)已删。

**待迁移(仍用旧散图,改到对应实体时再清理散图):**
- **爆炸**:`explosion_0..6`(7帧)。现 `Explosion.gd` 是运行时逐帧 `load()` 换贴图 —— 改成 7 帧图集 + AnimatedSprite2D 播一次自销(去掉运行时 load,性能更好)。下一个要做的。
- **敌机**:`enemy_0`。加飞行循环(机身/喷焰微动);注意 `SpriteFlash` 闪白要兼容 AnimatedSprite2D。
- **Boss / 子弹 / 敌弹**:`boss_body`、`boss_gun_main/sub`、`bullet`、`enemy_bullet` 按需做图集或保留静态。
- `stars`(滚动背景)保持现状。
- 全部迁移完后:删 `gen_pixel_art.py` 或标注废弃。

## 碰撞层
- 1=player,2=player_bullet,3(=1+2 的 mask 值,非层)。层位:player=layer1,player_bullet=layer2,enemy/boss_part/enemy_bullet=layer4。
- player(layer1,mask4)、player_bullet(layer2,mask4)、enemy(layer4,mask3)、enemy_bullet(layer4,mask1)、boss_part(layer4,mask0)。

## 校验状态
- 本机 VM 无 Godot 可执行文件,**未能跑 `--check-only`**;但用户机 **Godot 4.6.3** 已打开并导入项目:`.godot/global_script_class_cache.cfg` 注册了全部 14 个 class_name 脚本、贴图/音效均已导入,无导入报错。建议运行一局完整验证(2关+Boss+通关)。

## 已知清理项
- ~~多余嵌套目录 `PlaneShooter_godot/assets/art/`~~ **已于 2026-06-16 删除**(连同玩家旧散图)。

## 踩坑记录
- **ColorRect 视觉节点的引用类型要用 `CanvasItem`,不能用 `Node2D`。** ColorRect 属 Control→CanvasItem 分支。`visible` 在 CanvasItem 上;换 Sprite2D(属 Node2D)也兼容 CanvasItem。
- **实例化节点先 add_child 再设 global_position**,否则未入树时 global 变换不可靠。spawner/Boss 已按此修正。
- 启动日志 `... low quality OpenGL 3.3 support, switching to ANGLE` 是显卡驱动提示,无害。
- 手写大段文件时注意:单次 Edit/Write 有体积上限,超了会被静默截断,需分块写。

## 协作约定(跨工具)
- **本文件(CLAUDE.md)是项目上下文的唯一真源。** 根目录的 `AGENTS.md`(Codex 用)只是一句指引,指向本文件;任何工具更新进度都写这里,不要在 AGENTS.md 里另起一份,避免两边跑偏。
- **绝不碰 git。** 所有 git 操作(add/commit/push/分支/还原等)一律由用户手工进行。AI 不得执行任何 git 命令,也不要主动建议提交。用户 2026-06-16 明确要求。

## 变更历史
- **2026-06-17(Claude / 新机器环境搭建):** 在新的 **Intel Mac** 上从零重配 Aseprite MCP(旧 Windows 环境弃用)。从源码编译 Aseprite v1.3.17.2(Skia **m124**,产物 `.app` 包,移到 `~/projects/gitprojects/`);装 uv + Python 3.13 跑 `aseprite-mcp`(`~/projects/aseprite-mcp`);配进 **Cowork** 的 `claude_desktop_config.json`(uv 绝对路径 + `--directory` + 冗余 `ASEPRITE_PATH`)。**已建测试文件画像素并 scale=6 导出 PNG,MCP 工具链(create_canvas / draw_pixels_at / export_frame)全部验证可用。** 详见上方「Aseprite MCP 环境」专章。下一步:继续迁移**爆炸动画**为图集。
- **2026-06-16(Claude / Aseprite 工作流):** 接入 Aseprite MCP,启动「程序生成散图 → 手绘 spritesheet 图集」迁移(详见上方专章)。完成**玩家机**图集化:`player.aseprite`(2帧喷焰循环)→ `player.png` 图集 + `player_frames.tres`(SpriteFrames),`Player.tscn` 改用 AnimatedSprite2D(节点仍名 `Sprite`,依赖脚本零改动)。删除玩家旧散图与误建嵌套目录。爆炸/敌机/Boss 待迁移。
- **2026-06-15(Codex 改动):** 重写 `tools/gen_pixel_art.py` 的美术风格为"科幻像素风"(钢铁灰 + 青/紫霓虹、更锋利轮廓),并重新生成 `assets/art/` 下全部贴图(player_0/1、enemy_0、bullet、enemy_bullet、explosion_0..6、boss_body、boss_gun_main/sub、stars)。文件名/尺寸保持兼容,场景无需改。**当前磁盘上的美术是这版科幻风,不是最初的街机蓝版**(玩家机已被上面的 Aseprite 版覆盖)。若调机体外形可改 `scripts/player/Player.gd` 的 `_half_extents`。

