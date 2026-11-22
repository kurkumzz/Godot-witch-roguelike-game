extends Node2D

const FIRST_LEVEL := "res://scenes/level.tscn"
const PICKUP_RISE := 48.0

@onready var player := $Spawn/Player
@onready var gear: Sprite2D = $EquipmentTable/BookAndWand
@onready var halo: Sprite2D = $EquipmentTable/BookAndWand/Halo
@onready var light: PointLight2D = $EquipmentTable/BookAndWand/Light
var pickup_started := false


func _ready() -> void:
	if not RunState.slots.is_empty():
		pickup_started = true
		gear.hide()
		player.has_book_and_wand = true
		player.global_position = $Exit.global_position + Vector2(-72, -30)
		player.get_node("GameUI").refresh()


func _on_pickup_entered(body: Node2D) -> void:
	if body != player or pickup_started:
		return
	pickup_started = true
	halo.show()
	light.enabled = true
	var animation := create_tween()
	animation.tween_property(gear, "position:y", gear.position.y - PICKUP_RISE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	animation.parallel().tween_property(halo.get_node("Rays"), "rotation", TAU, 1.5)
	animation.tween_callback(halo.hide)
	animation.tween_callback(light.set_enabled.bind(false))
	var fly_from := gear.global_position + Vector2.UP * PICKUP_RISE
	animation.tween_method(_fly_to_player.bind(fly_from), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	animation.tween_callback(_finish_pickup)


func _fly_to_player(progress: float, fly_from: Vector2) -> void:
	gear.global_position = fly_from.lerp(player.global_position, progress)


func _finish_pickup() -> void:
	gear.hide()
	player.has_book_and_wand = true
	RunState.open_first_page()


func _physics_process(_delta: float) -> void:
	var at_exit: bool = $Exit.overlaps_body(player)
	$Exit/Hint.visible = at_exit and not pickup_started
	if at_exit and player.has_book_and_wand and RunState.pending_choices.is_empty():
		RunState.travel(FIRST_LEVEL, player)
