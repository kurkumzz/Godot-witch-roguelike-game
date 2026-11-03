class_name BaseEnemy
extends CharacterBody2D 

signal died

var player

@export var speedMovement = 300.0

@export var maxHealth: int = 5
@export var damage: int = 1

var health: int
var isDead := false


@onready var anim := $AnimatedSprite2D
@onready var states := $StateMachine

func _ready() -> void:
	health = maxHealth
	player = get_tree().get_first_node_in_group("player")
	states.init()
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#проверка урона. testTakeDamageButton временная кнопка!!
	if Input.is_action_just_pressed("testTakeDamageButton"):
		takeDamage(1)
		print("auch!")
		
	states.update(delta)
	move_and_slide()

func takeDamage(amount: int):
	if(isDead):
		return 
	
	health -= amount
	if(health <= 0):
		die()
		
func die():
	isDead = true
	died.emit()
	queue_free()

func distance() -> float:
	if not is_instance_valid(player): return INF
	return global_position.distance_to(player.global_position)
	
