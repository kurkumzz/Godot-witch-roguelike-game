extends Area2D

@export var speed: float = 200.0
@export var damage: int = 1
@export var lifetime: float = 3.0   # через сколько секунд исчезает сам

var direction: float = 1.0          # 1 = вправо, -1 = влево. Задаёт угорь при выстреле

func _ready() -> void:
	# когда снаряд во что-то врезался
	body_entered.connect(_on_body_entered)
	# сам удалится через lifetime секунд, чтобы не летел вечно
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	$Sprite2D.flip_h = direction < 0

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var final_damage := damage
		# разряд угря по мокрой ведьме бьёт вдвое сильнее
		if body.has_method("is_wet") and body.is_wet():
			final_damage *= 2
		body.take_damage(final_damage, global_position)
	# попал в ведьму или в стену — исчезаем
	queue_free()
