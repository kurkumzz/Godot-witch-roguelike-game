class_name projectile
extends Area2D

@export var speed := 300.0
@export var damage := 1
@export var lifetime := 1.5

const ELEMENT_SHADERS := {
	Element.Type.FIRE: preload("res://scenes/shaders/flame.gdshader"),
	Element.Type.WATER: preload("res://scenes/shaders/water_drop.gdshader"),
	Element.Type.ICE: preload("res://scenes/shaders/ice_shard.gdshader"),
	Element.Type.ELECTRIC: preload("res://scenes/shaders/lightning.gdshader"),
}

var direction := Vector2.RIGHT
var shooter: Node = null
var element: Element.Type = Element.Type.NONE


func launch(from: Vector2, dir: Vector2, owner_node: Node, elem: Element.Type = Element.Type.NONE) -> void:
	global_position = from
	direction = dir.normalized()
	rotation = direction.angle()
	shooter = owner_node
	element = elem
	var spell_material: ShaderMaterial = $Spell.material
	spell_material.shader = ELEMENT_SHADERS.get(element, ELEMENT_SHADERS[Element.Type.WATER])
	$Spell.modulate = Element.COLORS[element]
	reset_physics_interpolation()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body == shooter or is_queued_for_deletion():
		return
	if body is BaseEnemy:
		hit_enemy(body)
	queue_free()


func hit_enemy(enemy: BaseEnemy) -> void:
	enemy.receive_projectile(element, damage, direction)
