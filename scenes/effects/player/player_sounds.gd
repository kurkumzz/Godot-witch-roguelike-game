extends Node
## Звуки ведьмы. Слушает сигналы player.gd, поэтому сам скрипт игрока не трогаем.
## Чтобы поменять звук, перетащи другой файл в нужное поле в инспекторе.

@export var shoot_sound: AudioStream
@export var jump_sound: AudioStream
@export var land_sound: AudioStream
@export var hurt_sound: AudioStream
@export var death_sound: AudioStream
@export var dash_sound: AudioStream

@export_group("Громкость, дБ")
@export var shoot_volume := -6.0
@export var jump_volume := -4.0
@export var land_volume := -8.0
@export var hurt_volume := 0.0
@export var death_volume := 0.0
@export var dash_volume := -4.0

## Звук приземления только после настоящего падения, а не на каждом шаге со ступеньки.
@export var min_land_speed := 250.0

const BUS := &"SFX"

var _players := {}


func _ready() -> void:
	var player := get_parent()
	player.projectile_fired.connect(func(_shot): _play(&"shoot", 0.1))
	player.jumped.connect(func(_from_floor): _play(&"jump", 0.08))
	player.landed.connect(_on_landed)
	player.hurt.connect(func(_from): _play(&"hurt", 0.05))
	player.died.connect(func(): _play(&"death", 0.0))
	player.dash_started.connect(func(): _play(&"dash", 0.08))

	_add(&"shoot", shoot_sound, shoot_volume)
	_add(&"jump", jump_sound, jump_volume)
	_add(&"land", land_sound, land_volume)
	_add(&"hurt", hurt_sound, hurt_volume)
	_add(&"death", death_sound, death_volume)
	_add(&"dash", dash_sound, dash_volume)


func _add(key: StringName, stream: AudioStream, volume: float) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume
	# если шины SFX нет, Godot сам играет в Master
	p.bus = BUS if AudioServer.get_bus_index(BUS) != -1 else &"Master"
	p.max_polyphony = 3   # быстрые выстрелы не обрывают друг друга
	add_child(p)
	_players[key] = p


## pitch_spread: насколько случайно гулять высоте, чтобы повторы не резали слух.
func _play(key: StringName, pitch_spread: float) -> void:
	var p: AudioStreamPlayer = _players.get(key)
	if p == null:
		return
	p.pitch_scale = randf_range(1.0 - pitch_spread, 1.0 + pitch_spread)
	p.play()


func _on_landed(fall_speed: float) -> void:
	if fall_speed >= min_land_speed:
		_play(&"land", 0.1)
