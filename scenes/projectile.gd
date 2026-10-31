class_name projectile
extends Area2D

@export var speed := 300.0
@export var damage := 1
@export var lifetime := 1.5      # через сколько секунд снаряд исчезает сам

var direction := Vector2.RIGHT
var shooter: Node = null         # кто выстрелил, его снаряд игнорирует


func launch(from: Vector2, dir: Vector2, owner_node: Node) -> void:
	global_position = from
	direction = dir.normalized()
	rotation = direction.angle()
	shooter = owner_node


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body is BaseEnemy:
		body.takeDamage(damage)
	queue_free()   # исчезаем и при попадании в стену/пол
