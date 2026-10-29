extends Node

## Objeto singleton que maneja estados generales del nivel,
## almacena información entre niveles y ayuda a interconectar
## estados entre nodos y escenas distantes.

## Este patrón tranquilamente podría reemplazarse por alternativas,
## como propagación de señales entre padres, o inyección de
## dependencias, pero pueden crear mucho código repetido o
## generar mucho acople.


## Esto nos permite almacenar las armas que fuimos levantando
## entre los niveles. El primero son las armas con las que
## terminamos el nivel, el segundo son las que fuimos
## levantando.
var weapons_stash: Array = []
var weapons_available: Array = []


func notify_weapon_picked(weapon_scene: PackedScene) -> void:
	if !weapons_available.has(weapon_scene):
		weapons_available.push_back(weapon_scene)


## Señal y variable de ayuda que permite notificar la existencia
## del jugador actual a cualquiera interesado
signal current_player_changed(player)

var current_player: Player

func set_current_player(player: Player) -> void:
	current_player = player
	current_player_changed.emit(player)


## Señal genérica que avisa del cumplimiento de la condición
## de victoria a todos los interesados.
signal level_won()

func notify_level_won() -> void:
	weapons_stash.append_array(weapons_available)
	weapons_available = []
	level_won.emit()
