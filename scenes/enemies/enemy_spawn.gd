class_name EnemySpawn
extends Marker2D

## Точка появления врага в комнате. В инспекторе выбери, какого врага здесь создать.
@export var enemy_scene: PackedScene
## между этими точками слайм патрулирует (можно не задавать — тогда он стоит)
@export var patrol_a: Marker2D
@export var patrol_b: Marker2D
