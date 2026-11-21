extends Node2D

enum Room { START, EXIT, CORRIIDOR, REST, SPECIAL, COMBAT }
enum Complexity { EASY, MEDIUM, HARD }

@export var room: Room
@export var complexity: Complexity
