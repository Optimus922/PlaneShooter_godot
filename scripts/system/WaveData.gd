extends Resource
class_name WaveData
## 单波配置。复刻 Unity 版 LevelData.WaveData。
## 一波 = 生成 enemy_count 架敌机,每架间隔 spawn_interval 秒;
## 本波【全部被击毁】后停顿 delay_after_clear 秒再进下一波。

@export var enemy_count: int = 5
@export var spawn_interval: float = 0.8
@export var delay_after_clear: float = 1.5
## 本波使用的敌机场景。留空则用 EnemySpawner 的默认 enemy_scene。
@export var enemy_override: PackedScene
