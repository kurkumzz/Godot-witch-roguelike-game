class_name projectile
extends Area2D

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
	modulate = Element.COLORS[element]
	reset_physics_interpolation()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	if body is BaseEnemy:
		hit_enemy(body)
	queue_free()


func hit_enemy(enemy: BaseEnemy) -> void:
	var final_damage := damage
	var status := enemy.get_node_or_null("statusComp") as statusComp
	if status:
		final_damage = status.process_hit(element, damage)
	enemy.takeDamage(final_damage)
