extends Resource
class_name LevelData
## 关卡数据。复刻 Unity 版 LevelData(ScriptableObject)。
## 一关 = 若干 WaveData 顺序执行 + 可选 Boss。
## 在 Godot 里可建多个 .tres 资产、不改代码即可调关卡/加关卡。

@export var level_name: String = "Level 1"
## 按顺序执行的波次列表。
@export var waves: Array[WaveData] = []
## 本关 Boss(可空)。所有波次清完后生成,击杀 Boss 才算过关。留空则无 Boss。
@export var boss_scene: PackedScene
