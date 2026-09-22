## Esta State Machine en particular del player solo extiende la
## funcionalidad de la State Machine abstracta para ajustarse
## a las necesidades del personaje a usar. Para estructuras de juego
## más complejas, generalmente se abstraen estos métodos para crear
## un controller genérico que se pueda asignar a cualquier entidad.
extends GenericStateMachine


## Path al nodo de personaje a controlar. Si no se asigna,
## la máquina de estado no se inicializa.
@export var character: Node


# Asignamos el character a cada PlayerState
func _setup() -> void:
	if character == null:
		printerr("%s: character is not defined!" % name)
	for state: PlayerState in states_list:
		state.character = character


## Esta función deriva el handleo de cada golpe que recibe
## el personaje al estado actual particular, en vez de vincular
## la señal de "hit" a los estados que lo usan, ya que sino se
## podría ejecutar código de estados inactivos.
func notify_hit(amount: int) -> void:
	current_state.handle_event(&"hit", amount)


## Esta función hace casi lo mismo que "hit", solo que curando
## en vez de lastimando
func notify_healed(amount: int) -> void:
	current_state.handle_event(&"healed", amount)


## Esta es una función genérica que permite manejar los cambios
## de salud en el Player
func notify_hp_changed(current_hp: int, max_hp: int) -> void:
	current_state.handle_event(&"hp_changed", current_hp, max_hp)


func notify_mana_changed(current_mana: float, max_mana: float) -> void:
	current_state.handle_event(&"mana_changed", current_mana, max_mana)


func notify_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	current_state.handle_event(&"stamina_changed", current_stamina, max_stamina)
