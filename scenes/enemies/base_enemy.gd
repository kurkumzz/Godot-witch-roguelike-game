class_name BaseEnemy
extends CharacterBody2D

signal died

const ENEMY_GROUP := &"enemies"
const ALERT_RANGE_BONUS := 50.0
# Горизонтальный толчок от обычного снаряда сдвигает врага примерно на 3 пикселя.
const HIT_PUSH_SPEED := 55.0
const HIT_PUSH_DECAY := 600.0
const HIT_FLASH_SHADER := preload("res://scenes/shaders/hit.gdshader")
const HIT_FLASH_TIME := 0.15

@export_group("Движение и обнаружение")
@export var speedMovement := 100.0
@export var detectRange := 200.0
@export var loseRange := 300.0
@export var sightHeight := 15.0
@export var deadZone := 10.0

@export_group("Бой")
@export var maxHealth := 50
@export var damage := 1
@export var attackRange := 100.0

var player: Node2D
var facingDir := 1.0
var health: int
var isDead := false
var isHitted := false
var knockback_velocity := 0.0
var knockback_decay := 0.0
var flash_material: ShaderMaterial
var flash_tween: Tween

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var states := $StateMachine
@onready var status: statusComp = $statusComp


func _ready() -> void:
	health = maxHealth
	add_to_group(ENEMY_GROUP)
	player = get_tree().get_first_node_in_group("player") as Node2D
	setup_hit_flash()
	states.init()

func _physics_process(delta: float) -> void:
	if isDead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	var can_act := is_instance_valid(player) and status.can_act()
	if can_act:
		states.update(delta)
	else:
		velocity.x = 0.0

	# Состояния каждый кадр пишут velocity.x, поэтому отбрасывание накладываем после них
	if knockback_velocity != 0.0:
		velocity.x = knockback_velocity
		knockback_velocity = move_toward(knockback_velocity, 0.0, knockback_decay * delta)

	move_and_slide()
	if is_on_wall() and knockback_velocity * get_wall_normal().x < 0.0:
		knockback_velocity = 0.0
	if can_act:
		damage_overlapping_player()

func receive_projectile(element: Element.Type, damage_amount: int, direction: Vector2) -> void:
	if isDead:
		return
	# Сохраняем импульс перегрузки, если следующий снаряд попал вдогонку.
	if absf(knockback_velocity) < HIT_PUSH_SPEED:
		knockback_velocity = signf(direction.x) * HIT_PUSH_SPEED
		knockback_decay = HIT_PUSH_DECAY
	isHitted = true
	var final_damage := status.process_hit(element, damage_amount, direction)
	takeDamage(final_damage)

func takeDamage(amount: int) -> void:
	if isDead:
		return

	health -= amount
	if health <= 0:
		die()
		return
	play_hit_flash()

func die() -> void:
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
	if not is_instance_valid(player):
		return INF
	return global_position.distance_to(player.global_position)

func currentDir(target: float) -> float:
	return signf(target - global_position.x)

func flipSprite(dir: float) -> void:
	anim.flip_h = dir < 0
	facingDir = -1.0 if anim.flip_h else 1.0

func damage_overlapping_player() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)

func isPlayerInHeight() -> bool:
	return absf(player.global_position.y - global_position.y) < sightHeight

func canSeePlayerCheck() -> bool:
	return currentDir(player.global_position.x) == facingDir and isPlayerInHeight()

func detects_player() -> bool:
	var distance := distanceBetween()
	var alerted := isHitted and distance < detectRange + ALERT_RANGE_BONUS and isPlayerInHeight()
	if alerted or (distance < detectRange and canSeePlayerCheck()):
		isHitted = false
		return true
	return false
