extends Node2D

const BURST := preload("res://scenes/effects/projectiles/projectile_burst.gd")
const SHADERS := {
	Element.Type.FIRE: preload("res://scenes/shaders/flame.gdshader"),
	Element.Type.WATER: preload("res://scenes/shaders/water_drop.gdshader"),
	Element.Type.ICE: preload("res://scenes/shaders/ice_shard.gdshader"),
	Element.Type.ELECTRIC: preload("res://scenes/shaders/lightning.gdshader"),
}

var element: Element.Type


func ignite(element_type: Element.Type) -> void:
	element = element_type
	var tint: Color = Element.COLORS[element]
	var spell_material: ShaderMaterial = $Core.material
	spell_material.shader = SHADERS.get(element, SHADERS[Element.Type.WATER])
	$Core.modulate = tint
	$Light.color = tint
	$Halo.self_modulate = Color(tint, 0.28)
	# Первый выброс должен начинаться у посоха, даже если снаряд создан в этом же кадре.
	$Trail.force_update_transform()
	$Trail.configure(element, false)


func disperse(on_contact: bool) -> void:
	var world := get_parent().get_parent()
	var burst := BURST.new()
	burst.element = element
	burst.on_contact = on_contact
	world.add_child(burst)
	burst.global_transform = global_transform
	burst.reset_physics_interpolation()
	# Выпущенные частицы догасают в мире после удаления хитбокса.
	var trail: CPUParticles2D = $Trail
	trail.emitting = false
	trail.reparent(world)
	trail.z_index = burst.z_index - 1
	trail.create_tween().tween_callback(trail.queue_free).set_delay(trail.lifetime)
