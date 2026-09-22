extends Control

## Escena que presenta la información que figura en pantalla durante
## el juego. Maneja tanto lo que es barras de salud como información
## general.

@onready var hp_progress_1: TextureProgressBar = $"%HpProgress1"
@onready var hp_progress_2: TextureProgressBar = $"%HpProgress2"

@onready var fading_elements: Array = [hp_progress_1]

@export var fade_duration: float = 5.0
@export var fade_delay: float = 2.0

var stats_tween: Tween


# Recupera la información de cuál es el Player actual desde GameState.
func _ready() -> void:
	GameState.current_player_changed.connect(_on_current_player_changed)


## Cuando se asigna un Player nuevo, se conecta a las señales que
## interesan, y se refresca la data.
func _on_current_player_changed(player: Player) -> void:
	player.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(player.hp, player.max_hp)


# Callback de cambio de HP.
func _on_hp_changed(hp: int, hp_max: int) -> void:
	hp_progress_1.max_value = hp_max
	hp_progress_2.max_value = hp_max
	hp_progress_1.value = hp
	hp_progress_2.value = hp
	_animate_fade()


# Función de ayuda para animar el fade-out de elementos de la escena.
func _animate_fade() -> void:
	if !is_inside_tree():
		return
	
	if stats_tween:
		stats_tween.kill()
	stats_tween = create_tween()
	
	for element in fading_elements:
		element.modulate = Color.WHITE
		stats_tween.set_parallel().tween_property(
			element,
			"modulate",
			Color.TRANSPARENT,
			fade_duration
		).set_trans(Tween.TRANS_SINE).set_delay(fade_delay)
