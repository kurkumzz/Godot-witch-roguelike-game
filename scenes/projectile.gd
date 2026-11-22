class_name projectile
extends Area2D

signal launched(element_type: Element.Type)
signal dispersed(on_contact: bool)
signal enemy_hit(world_position: Vector2)

@export var speed := 300.0
@export var damage := 1
@export var lifetime := 1.5

var direction := Vector2.RIGHT
var shooter: Node = null
var element: Element.Type = Element.Type.NONE


func launch(from: Vector2, dir: Vector2, owner_node: Node, elem: Element.Type = Element.Type.NONE) -> void:
	global_position = from
	direction = dir.normalized()
	rotation = direction.angle()
	shooter = owner_node
	element = elem
	reset_physics_interpolation()
	launched.emit(element)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(_disperse.bind(false))


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body == shooter or is_queued_for_deletion():
		return
	if body is BaseEnemy:
		hit_enemy(body)
	_disperse(true)


func _disperse(on_contact: bool) -> void:
	if is_queued_for_deletion():
		return
	queue_free()
	dispersed.emit(on_contact)


func hit_enemy(enemy: BaseEnemy) -> void:
	if enemy.isDead:
		return
	enemy.receive_projectile(element, damage, direction)
	enemy_hit.emit(global_position)
