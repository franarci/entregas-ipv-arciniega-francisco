## Este estado hereda de un State intermedio llamado TurretState
## que extiende la interfaz de State con comportamientos específicos
## (se puede abrir el script con Ctrl+click)
extends TurretState

# Definimos variables para manejar el comportamiento de "caminata"

## Radio de búsqueda del punto deseado objetivo
@export var wander_radius: Vector2
## Velocidad de aceleración durante caminata
@export var speed: float
## Velocidad máxima durante caminata
@export var max_speed: float
## Con esta variable controlamos cuál es la distancia mínima para considerar
## que se llegó al "punto" deseado, y evitar situaciones de "dar vueltas"
## (esto se puede ver quitando el chequeo o seteandolo en 0.0)
@export var pathfinding_step_threshold: float = 5.0

# El path que definimos con el pathfinding
var path: PackedVector2Array = PackedVector2Array()


func enter() -> void:
	# Al ingresar, primero definimos si tenemos un "pathfinding" para usar
	if character.pathfinding != null:
		
		# Luego definimos un punto random "objetivo"
		var random_point: Vector2 = (
			character.global_position + 
			Vector2(
				randf_range(-wander_radius.x, wander_radius.x),
				randf_range(-wander_radius.y, wander_radius.y)
			)
		)
		
		# Y le solicitamos al pathfinding que nos de una ruta al mismo
		path = character.pathfinding.get_simple_path(
			character.global_position,
			random_point
		)
		
		# Si no hay ruta, o la misma es muy corta, ignoramos y regresamos a Idle
		if path.is_empty() || path.size() == 1:
			finished.emit(&"idle")
		else:
			## Sino, iniciamos y determinamos la animación a usar dependiendo
			## de la cercanía del Player
			if character.target != null:
				character._play_animation(&"walk_alert")
			else:
				character._play_animation(&"walk")
	else:
		# Si no es asi, regresamos al estado Idle
		finished.emit(&"idle")


func exit() -> void:
	# Al salir, limpiamos el camino para que no genere conflictos después
	path = PackedVector2Array()


func update(_delta: float) -> void:
	# Primero chequeamos si debemos entrar en Alert
	if character._can_see_target():
		finished.emit(&"alert")
		return
	
	# Luego chequeamos si terminamos de caminar y hay que regresar a Idle
	if path.is_empty():
		finished.emit(&"idle")
		return
	
	# Tomamos el siguiente punto a recorrer
	var next_point: Vector2 = path[0]
	
	# Chequeamos que no "llegamos" al punto o cualquiera sucesivo
	while (
		character.global_position.distance_to(next_point) < pathfinding_step_threshold
	):
		# Si llegamos, quitamos el punto inmediato
		path.remove_at(0)
		
		# Si el camino está vacío, llegamos y regresamos a Idle
		if path.is_empty():
			finished.emit(&"idle")
			return
		
		# Sino, definimos el siguiente punto a moverse
		next_point = path[0]
	
	## Aplicamos la velocidad para el movimiento, definiendo la dirección al
	## próximo punto a moverse y aplicandole la velocidad
	character.velocity = (
		character.velocity +
		character.global_position.direction_to(next_point) * speed
	).limit_length(max_speed) # Acá limitamos la velocidad a un máximo determinado
	
	# Aplicamos el movimiento en el personaje
	character.move_and_slide()
	
	# Y orientamos al cuerpo en la dirección de movimiento
	character.body_anim.flip_h =  character.velocity.x < 0


func _handle_body_entered(body: Node) -> void:
	super._handle_body_entered(body)
	
	## No se ejecuta directamente el "walk_alert", sino que se ejecuta una
	## animación de transición
	character._play_animation(&"alert")


func _handle_body_exited(body) -> void:
	super._handle_body_exited(body)
	
	## No se ejecuta directamente el "walk", sino que se ejecuta una
	## animación de transición
	character._play_animation(&"go_normal")


# Manejamos la transicion de animaciones "intermedias" a animaciones finales
func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"alert":
			character._play_animation(&"walk_alert")
		&"go_normal":
			character._play_animation(&"walk")


func handle_input(_event: InputEvent) -> void:
	return
