extends Node2D

@export var startRooms: Array[PackedScene]
@export var exitRooms: Array[PackedScene]
@export var easyRooms: Array[PackedScene]
@export var mediumRooms: Array[PackedScene]
@export var hardRooms: Array[PackedScene]
@export var calmRooms: Array[PackedScene]
@export var middle_count := 4

#camera sett
var currentRoom: Node2D

@onready var roomsRoot: Node2D = $Rooms
@onready var player: Node2D = $player
@onready var camera: Camera2D = $player/Camera2D

var rng : RandomNumberGenerator

func _ready() -> void:
	rng = RunState.map_rng()
	var sequence := buildSequence()
	placeRooms(sequence)
	placePlayer()

func _physics_process(_delta: float) -> void:
	for room in roomsRoot.get_children():
		var rect: Rect2 = room.get_node("Bounds").get_global_rect()
		if rect.has_point(player.global_position) and room != currentRoom:
			currentRoom = room
			applyLimits(rect)
	
func applyLimits(rect: Rect2) -> void:
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)
#возвращает последовательность комнат

func buildSequence() -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	result.append(pick(startRooms))
	result.append(pick(easyRooms))
	result.append(pick(mediumRooms))
	result.append(pick(exitRooms))
	return result

#возвращает случайный индекс массива
func pick(list: Array[PackedScene]) -> PackedScene:
	var index := rng.randi_range(0, list.size() - 1)
	return list[index]

func placeRooms(sequence: Array[PackedScene]) -> void:
	var cursor := Vector2.ZERO
	
	for scene in sequence:
		#instantiate создает новый экземпляр класса в памяти
		var room := scene.instantiate() as Node2D
		
		var doorLeft := room.get_node("Doors/DoorLeft") as Marker2D
		var doorRight := room.get_node("Doors/DoorRight") as Marker2D
		
		room.position = cursor - doorLeft.position
		
		#add_child помещает объект в дерево, становистя ребенком roomRoot
		roomsRoot.add_child(room)
		cursor = doorRight.global_position
	

func placePlayer() -> void:
	var room := roomsRoot.get_child(0)
	var doorLeft := room.get_node("Doors/DoorLeft") as Marker2D
	player.global_position = doorLeft.global_position + Vector2(64, -32)
