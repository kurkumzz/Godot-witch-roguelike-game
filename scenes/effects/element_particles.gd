extends CPUParticles2D

const TEXTURES := {
	Element.Type.FIRE: preload("res://graphics/particles/ember.svg"),
	Element.Type.WATER: preload("res://graphics/particles/drop.svg"),
	Element.Type.ICE: preload("res://graphics/particles/snowflake.svg"),
	Element.Type.ELECTRIC: preload("res://graphics/particles/spark.svg"),
}


func configure(element: Element.Type, on_enemy: bool) -> void:
	emitting = false
	if not TEXTURES.has(element):
		return
	texture = TEXTURES[element]
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	local_coords = false
	color = Element.COLORS[element]
	amount = 8 if on_enemy else 5
	lifetime = 0.6 if on_enemy else 0.18
	scale_amount_min = 0.55
	scale_amount_max = 0.9
	initial_velocity_min = 10.0
	initial_velocity_max = 24.0
	direction = Vector2.UP
	spread = 28.0
	gravity = Vector2(0.0, -30.0)
	match element:
		Element.Type.WATER:
			direction = Vector2.DOWN
			gravity = Vector2(0.0, 70.0)
		Element.Type.ICE:
			direction = Vector2.DOWN
			spread = 65.0
			gravity = Vector2(0.0, 8.0)
		Element.Type.ELECTRIC:
			spread = 180.0
			initial_velocity_max = 48.0
			gravity = Vector2.ZERO
	if on_enemy:
		emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		emission_rect_extents = Vector2(11, 8)
	emitting = true
