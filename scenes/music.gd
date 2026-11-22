extends AudioStreamPlayer
## Фоновая музыка. Подключена как автозагрузка (Project Settings → Globals → Autoload),
## поэтому не прерывается при переходе шабаш ↔ болото.

const TRACK := preload("res://sounds/background music.mp3")
const VOLUME_DB := -10.0   # громкость музыки, чтобы не перебивала звуки


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # играет и на паузе
	stream = TRACK
	stream.loop = true
	volume_db = VOLUME_DB
	bus = &"Music" if AudioServer.get_bus_index(&"Music") != -1 else &"Master"
	play()
