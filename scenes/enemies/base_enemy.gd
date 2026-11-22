class_name BaseEnemy
extends CharacterBody2D

signal died

#движение
@export var speedMovement: float = 100.0
var facingDir := 1.0

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
@export var immovable := false  

const ENEMY_GROUP := &"enemies"
const ALERT_RANGE_BONUS := 50.0
# Горизонтальный толчок от обычного снаряда сдвигает врага примерно на 3 пикселя.
const HIT_PUSH_SPEED := 55.0
const HIT_PUSH_DECAY := 600.0

#вспышка при получении урона (тот же шейдер, что у игрока)
const HitMaterial := preload("res://scenes/effects/hit_material.gd")
const HIT_FLASH_TIME := 0.15   # за сколько белый возвращается к обычному
var flash_material := HitMaterial.new()

#расстояния
@export var detectRange: float = 200.0
@export var loseRange: float = 300.0
@export var sightHeight := 15.0
@export var deadZone: float = 10.0
@export var attackRange: float = 100.0


#гет компоненты
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var states = $StateMachine
@onready var label: Label = $Label
var player: Node2D
@onready var hitbox: Area2D = $Hitbox #нужно для лучшей проверки хитбоксов для получения урона
@onready var status: statusComp = $statusComp

func _ready() -> void:
	health = maxHealth
	add_to_group(ENEMY_GROUP)   # по этой группе электро-цепь находит соседей
	player = get_tree().get_first_node_in_group("player") as Node2D
	anim.material = flash_material
	states.init()

func _physics_process(delta: float) -> void:
	if isDead:
		return
	# Add the gravity.
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
	if not immovable and absf(knockback_velocity) < HIT_PUSH_SPEED:
		knockback_velocity = signf(direction.x) * HIT_PUSH_SPEED
		knockback_decay = HIT_PUSH_DECAY
	isHitted = true
	var final_damage := status.process_hit(element, damage_amount, direction)
	takeDamage(final_damage)

func takeDamage(amount: int) -> void:
	if(isDead):
		return

	health -= amount
	if(health <= 0):
		die()
		return
	flash_material.flash(anim, HIT_FLASH_TIME)

func die() -> void:
	isDead = true
	died.emit()
	queue_free()

## Отбрасывание: force.x - горизонтальная скорость (знак = направление),
## force.y - вертикальный подброс (отрицательное = вверх), decay - как быстро гаснет x.
func apply_knockback(force: Vector2, decay := 800.0) -> void:
	if immovable:
		return
	knockback_velocity = force.x
	knockback_decay = decay
	velocity.y = force.y

func distanceBetween() -> float:
	if not is_instance_valid(player): return INF
	return global_position.distance_to(player.global_position)

func currentDir(target: float) -> float:
	var dx: float = target - global_position.x
	var dir: float = signf(dx)
	return dir

func flipSprite(dir: float) -> void:
	anim.flip_h = dir < 0
	if(anim.flip_h):
		facingDir = -1.0
	else:
		facingDir = 1.0

func damage_overlapping_player() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, global_position)

func isPlayerInHeight() -> bool:
	var heightDifference: float = absf(player.global_position.y - global_position.y)
	return heightDifference < sightHeight
func canSeePlayerCheck() -> bool:
	var playerDir: float = currentDir(player.global_position.x)
	return playerDir == facingDir and isPlayerInHeight()

func detects_player() -> bool:
	var distance := distanceBetween()
	var alerted := isHitted and distance < detectRange + ALERT_RANGE_BONUS and isPlayerInHeight()
	if alerted or (distance < detectRange and canSeePlayerCheck()):
		isHitted = false
		return true
	return false
