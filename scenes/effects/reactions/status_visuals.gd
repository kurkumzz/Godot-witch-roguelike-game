extends Node2D
## Отмечает состояния на самом враге. Цвет, старые искры и значки задаёт statusComp.

const Flash := preload("res://scenes/effects/reactions/reaction_flash.gd")
const Chain := preload("res://scenes/effects/reactions/chain_lightning.gd")
const REACTIONS: Dictionary[String, GDScript] = {
	"ИСПАРЕНИЕ": preload("res://scenes/effects/reactions/vaporize.gd"),
	"ЗАМОРОЗКА": preload("res://scenes/effects/reactions/freeze.gd"),
	"ЗАРЯД": preload("res://scenes/effects/reactions/charge.gd"),
	"ПЕРЕГРУЗКА": preload("res://scenes/effects/reactions/overload.gd"),
	"СВЕРХПРОВОДИМОСТЬ": preload("res://scenes/effects/reactions/superconduct.gd"),
	"РАСКОЛ": preload("res://scenes/effects/reactions/shatter.gd"),
}

@onready var status: statusComp = $"../statusComp"


func on_status_changed(_status: statusComp.Status) -> void:
	queue_redraw()


func on_reaction(reaction_name: String) -> void:
	if not REACTIONS.has(reaction_name):
		return
	var flash: Flash = REACTIONS[reaction_name].new()
	# Вспышка переживает смертельный удар, но удаляется при смене уровня.
	get_parent().get_parent().add_child(flash)
	flash.global_position = global_position
	flash.reset_physics_interpolation()


func on_chain_jumped(from_pos: Vector2, to_pos: Vector2) -> void:
	var chain := Chain.new()
	get_parent().get_parent().add_child(chain)
	chain.set_endpoints(from_pos, to_pos)
	chain.reset_physics_interpolation()


func _draw() -> void:
	if status.has_status(statusComp.Status.FROZEN):
		for side: float in [-1.0, 1.0]:
			Flash.draw_crystal(self, Vector2(side * 7, 13), Vector2(side * 8, -20), 3.5,
					Color("#609ec1"), Color("#d3fbff"))
	elif status.has_status(statusComp.Status.CHILL):
		draw_line(Vector2(-13, 12), Vector2(-6, 12), Color("#a9eafd"))
		draw_line(Vector2(4, 12), Vector2(12, 12), Color("#a9eafd"))
	if status.has_status(statusComp.Status.CHARGED):
		for side: float in [-1.0, 1.0]:
			var trace := PackedVector2Array([Vector2(side * 12, -10), Vector2(side * 16, -3),
					Vector2(side * 12, -4), Vector2(side * 15, 6)])
			draw_polyline(trace, Color("#fff08b"), 1.0)
	if status.has_status(statusComp.Status.FRAGILE):
		draw_polyline(PackedVector2Array([Vector2(7, -12), Vector2(0, -4),
				Vector2(4, -2), Vector2(-3, 6)]), Color("#f6daff"), 1.5)
		draw_line(Vector2(1, -5), Vector2(-4, -7), Color("#c9abef"))
