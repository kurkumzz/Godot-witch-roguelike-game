extends Node2D

@export var startRooms: Array[PackedScene]
@export var exitRooms: Array[PackedScene]
@export var easyRooms: Array[PackedScene]
@export var mediumRooms: Array[PackedScene]
@export var hardRooms: Array[PackedScene]
@export var calmRooms: Array[PackedScene]

var currentRoom: Node2D
@onready var roomsRoot: Node2D = $Rooms
@onready var player: Node2D = $player
@onready var camera: Camera2D = $player/Camera2D


func _ready() -> void:
	var rng := RunState.map_rng()
	var cursor := Vector2.ZERO
	for pool: Array in [startRooms, easyRooms, mediumRooms, exitRooms]:
		var scene: PackedScene = pool[rng.randi_range(0, pool.size() - 1)]
		var room := scene.instantiate() as Node2D
		room.position = cursor - room.door_left
		roomsRoot.add_child(room)
		cursor = room.position + room.door_right
	player.global_position = roomsRoot.to_global(Vector2(64, -32))


func _physics_process(_delta: float) -> void:
	update_camera_room()


func update_camera_room() -> void:
	for room in roomsRoot.get_children():
		var bounds: Rect2 = room.get_node("Bounds").get_global_rect()
		if bounds.has_point(player.global_position):
			if room != currentRoom:
				currentRoom = room
				camera.limit_left = int(bounds.position.x)
				camera.limit_top = int(bounds.position.y)
				camera.limit_right = int(bounds.end.x)
				camera.limit_bottom = int(bounds.end.y)
			return
