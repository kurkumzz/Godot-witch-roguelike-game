class_name BaseEnemy
extends CharacterBody2D

signal died

#движение
@export var speedMovement = 300.0

#здоровье и урон
@export var maxHealth: int = 50
var health: int
@export var damage: int = 1

#статус
var isDead := false
var isHitted := false

#отбрасывание (перегрузка и другие эффекты). Перебивает скорость от состояний
var knockback_velocity := 0.0
var knockback_decay := 0.0

#вспышка при получении урона (тот же шейдер, что у игрока)
const HIT_FLASH_SHADER := preload("res://scenes/shaders/hit.gdshader")
const HIT_FLASH_TIME := 0.15   # за сколько белый возвращается к обычному
var flash_material: ShaderMaterial
var flash_tween: Tween

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
	add_to_group("enemies")   # по этой группе электро-цепь находит соседей
	player = get_tree().get_first_node_in_group("player")
	setup_hit_flash()
	states.init()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	states.update(delta)

	# Состояния каждый кадр пишут velocity.x, поэтому отбрасывание накладываем после них
	if knockback_velocity != 0.0:
		velocity.x = knockback_velocity
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)
		if is_on_wall():
			knockback_velocity = 0.0

	move_and_slide()
	damage_overlapping_player()

func takeDamage(amount: int):
	if(isDead):
		return

	health -= amount
	if(health <= 0):
		die()
		return
	play_hit_flash()

func die():
	isDead = true
	died.emit()
	queue_free()

## Отбрасывание: force.x - горизонтальная скорость (знак = направление),
## force.y - вертикальный подброс (отрицательное = вверх), decay - как быстро гаснет x.
func apply_knockback(force: Vector2, decay := 800.0) -> void:
	knockback_velocity = force.x
	knockback_decay = decay
	velocity.y = force.y

# --- Вспышка при уроне ---

func setup_hit_flash() -> void:
	# Отдельный материал на каждого врага, иначе вспыхивали бы все сразу
	flash_material = ShaderMaterial.new()
	flash_material.shader = HIT_FLASH_SHADER
	flash_material.set_shader_parameter("flash_amount", 0.0)
	anim.material = flash_material

func play_hit_flash() -> void:
	if flash_tween:
		flash_tween.kill()
	flash_material.set_shader_parameter("flash_amount", 1.0)
	flash_tween = create_tween()
	flash_tween.tween_property(flash_material, "shader_parameter/flash_amount", 0.0, HIT_FLASH_TIME)

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
