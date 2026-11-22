extends Sprite2D

@export_file("*.tscn") var destination: String
@export var caption: String


func _ready() -> void:
	$Hint.text = "E · " + caption
	$Trigger.body_entered.connect(func(body): 
		if body.is_in_group("player"): $Hint.show())
	$Trigger.body_exited.connect(func(body):
		if body.is_in_group("player"): $Hint.hide())


func _unhandled_input(event: InputEvent) -> void:
	if $Hint.visible and event.is_action_pressed("enter_gate"):
		get_viewport().set_input_as_handled()
		RunState.travel(destination, get_tree().get_first_node_in_group("player"))
