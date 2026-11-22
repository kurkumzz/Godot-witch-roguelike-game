extends Node2D

enum Room { START, EXIT, CORRIIDOR, REST, SPECIAL, COMBAT }
enum Complexity { EASY, MEDIUM, HARD }

@export var room: Room
@export var complexity: Complexity

@export var door_left := Vector2(0, 480)
@export var door_right := Vector2(1280, 480)
