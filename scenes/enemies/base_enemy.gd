class_name BaseEnemy
extends CharacterBody2D 

signal died

#движение
@export var speedMovement = 300.0

#здоровье и урон
@export var maxHealth: int = 10
var health: int
@export var damage: int = 1

#статус
var isDead := false
var isHitted := false

#расстояния
@export var detectRange: float = 200.0
@export var loseRange: float = 300.0
@export var attackRange: float = 60.0

#гет компоненты
@onready var anim := $AnimatedSprite2D
@onready var states := $StateMachine
var player
@onready var hitbox: Area2D = $Hitbox #нужно для лучшей проверки хитбоксов для получения урона

func _ready() -> void:
	health = maxHealth
	player = get_tree().get_first_node_in_group("player")
	states.init()
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	states.update(delta)
	move_and_slide()
	damage_overlapping_player()

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

func distanceBetween() -> float:
	if not is_instance_valid(player): return INF
	return global_position.distance_to(player.global_position)
	
func currentDir(target: float) -> float:
	var dx = target - global_position.x
	var dir = sign(dx)
	return dir

func flipSprite(dir: float):
	anim.flip_h = dir < 0

func damage_overlapping_player() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)
