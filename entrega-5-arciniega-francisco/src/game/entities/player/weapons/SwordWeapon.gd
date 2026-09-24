extends AbstractWeapon

## Arma que representa a una espada. Ideal para tormentas que se aproximan,
## o para gente que respira muy bien mientras duerme.
## Los ataques consumen Stamina.

## Ataque 1 - Corte normal, daño bajo, buen knockback
## Ataque 2 - Corte a distancia, bajo knockback
## Ataque 3 - Corte con dash teleport, buen daño, lento en cargar.

@onready var attacks_anim: AnimationPlayer = $AttacksAnim
@onready var sword_pivot: Node2D = $SwordPivot
@onready var dash_raycast: RayCast2D = $DashRaycast
@onready var dash_line: Line2D = $DashLine
@onready var line_raycast: RayCast2D = $"%LineRaycast"

@export var projectile_scenes: Array[PackedScene]
@export var stamina_drain: PackedFloat32Array = PackedFloat32Array([1.0, 2.0, 7.0])
@export var anim_map: Dictionary[AbstractWeapon.ATT_TYPE, StringName] = {
	ATT_TYPE.PRIMARY: &"cut",
	ATT_TYPE.SECONDARY: &"far_cut",
	ATT_TYPE.SPECIAL: &"dash_cut"
}

@export var cut_damage: int = 3
@export var cut_push: float = 500.0
@export var extra_impulse: float = 50.0
@export var safety_shape: Shape2D
@export var dash_damage: int = 5

var aim_point: Vector2
var character: Player


func _ready() -> void:
	# Inicializamos los puntos de la línea de telegrafía del Ataque 3.
	dash_line.points = [Vector2.ZERO, Vector2.ONE]


## Nos aseguramos que la animación "RESET" se reproduzca por default
## para que no queden artefactos de animación (como FX congelados).
func enter() -> void:
	super.enter()
	attacks_anim.play(&"RESET")


func exit() -> void:
	super.exit()
	attacks_anim.play(&"RESET")


func update_weapon(_delta: float, p_character: Node, can_attack: bool = true) -> void:
	if attacks_anim.is_playing() && attacks_anim.current_animation != &"RESET":
		# Acá solo me mantengo apuntando si tengo habilitada esa función.
		# Esto es como corrección de apuntado para compensar por el delay
		# aplicado por la animación de disparo.
		
		# Aqui giramos el arma para que no se vea tonto, y sumamos 180 grados
		# a la rotación si el scale.x es -1 para apuntar correctamente.
		var direction: Vector2 = global_position.direction_to(aim_point)
		sword_pivot.scale.x = 1.0 - 2.0 * float(direction.x < 0)
		sword_pivot.rotation = direction.angle() + PI * float(direction.x < 0)
	elif can_attack:
		# Y sino, manejo el disparo acorde al drenado de Stamina que corresponde.
		for input in input_map.keys():
			if (
				Input.is_action_just_pressed(input) &&
				p_character.stamina >= stamina_drain[input_map[input]]
			):
				attack(input_map[input])
				
				# Excepción particular, solo dreno stamina de inmediato
				# para el primer ataque.
				if input_map[input] == ATT_TYPE.PRIMARY:
					p_character.sum_stamina(-stamina_drain[ATT_TYPE.PRIMARY])
				
				# Cacheo el personaje para usarlo después
				self.character = p_character
	
	# Actualizamos la línea de Dash, aunque solo se use durante el ataque dash.
	var mouse_pos: Vector2 = get_global_mouse_position()
	line_raycast.target_position = line_raycast.to_local(get_global_mouse_position())
	dash_line.points[1] = dash_line.to_local(
		line_raycast.get_collision_point() if line_raycast.is_colliding() else mouse_pos
		)


func attack(type: int) -> void:
	# No disparo de inmediato, sino que delego a una animación de disparo
	attacks_anim.play(anim_map[type])
	aim_point = get_global_mouse_position()


# La animación de disparo llama a esta función que va a ser la que instancie
# el proyectil
func _attack(type: int) -> void:
	var projectile_instance: Node = projectile_scenes[type].instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.initialize(
		global_position,
		global_position.direction_to(aim_point))
	character.sum_stamina(-stamina_drain[type])


# Función que maneja el ataque especial de corte con dash.
# Esta función utiliza queries de Raycast para aplicar daño y determinar
# el punto de finalización, para no atravesar las paredes.
# Al terminar el ataque, teletransporta al personaje al punto final.
# También aplica un cálculo de compensación de impacto para casos
# donde el teletransporte termina muy cerca de un muro.
func _attack_dash(type: int) -> void:
	# Se determina el punto objetivo
	aim_point = get_global_mouse_position()
	var final_point: Vector2 = aim_point
	
	# Inicializamos el Raycast que vamos a usar
	dash_raycast.position = Vector2.ZERO
	dash_raycast.clear_exceptions()
	
	# Seteamos el punto de casteo. La propiedad Raycast2D.target_position se
	# maneja en coordenadas locales, por lo que traducimos
	dash_raycast.target_position = dash_raycast.to_local(aim_point)
	# Y forzamos la primera query de Raycast
	dash_raycast.force_raycast_update()
	
	# Usamos el while para saltar de target en target, y solo corta
	# si llego al objetivo o si se chocó contra una pared.
	while dash_raycast.is_colliding():
		# Recuperamos el objeto con el que colisionó el Raycast
		var collider = dash_raycast.get_collider()
		# Si puede recibir golpes, es un objetivo, sino, es pared.
		# Usamos duck typing para determinar el tipo.
		if collider.has_method(&"notify_hit"):
			# Te pego que te pego
			collider.notify_hit(-dash_damage)
			# Lo agrego a excepciones para que no colisione más el
			# Raycast con el objeto (sino es un while true)
			dash_raycast.add_exception(collider)
			# Y reiniciamos el Raycast usando como nuevo punto el
			# punto de colisión.
			dash_raycast.global_position = dash_raycast.get_collision_point()
			dash_raycast.target_position = dash_raycast.to_local(aim_point)
			dash_raycast.force_raycast_update()
		else:
			# Al ser pared, corto el trayecto, me quedo como punto final
			# el punto de colisión, y retrocedo unos píxeles para evitar
			# solapamiento con la pared.
			final_point = dash_raycast.get_collision_point()
			final_point += dash_raycast.get_collision_normal() * 6.0
			break
	
	# Llamamos al efectito de corte (que no hace daño, solo es FX)
	var cut_effect: Node = projectile_scenes[type].instantiate()
	projectile_container.add_child(cut_effect)
	cut_effect.initialize(
		global_position,
		final_point,
		global_position.direction_to(aim_point))
	
	# Y hacemos algo interesante. Este paso compensa por las colisiones
	# del cuerpo del jugador, para evitar que la "teletransportación" deje
	# al personaje atrapado en la colisión del entorno.
	# Para ello, hacemos una query directamente al servidor de colisiones
	# y que nos devuelva los posibles puntos de colisión con los que
	# calcular un Normal.
	# No es perfecto, si es un punto válido pero esta en medio de dos obstáculos
	# es probable que el personaje quede atrapado, para eso habria que hacer un
	# paso antes de iniciar que verifique que el punto final de apuntado es
	# válido, y si no lo es buscar uno válido en el trayecto. Como diría Aldo,
	# tarea para el hogar.
	
	# Primero obtenemos el espacio al que hacer la query
	var space_state: PhysicsDirectSpaceState2D = PhysicsServer2D.space_get_direct_state(get_world_2d().space)
	
	# Luego inicializamos el "objeto" de query y llenamos sus parámetros
	
	var shape_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	
	# Le aplicamos la shape del jugador
	shape_query.set_shape(safety_shape)
	# Ponemos que su capa de colisión sea 1 (World) en binario
	shape_query.collision_mask = 0b00000000000000000001
	# Le aplicamos el transform global de la espada pero trasladado (es decir,
	# con el origin/position cambiado) al punto donde queremos hacer
	# la query con la shape.
	shape_query.transform = global_transform.translated(to_local(final_point + Vector2.UP * 4))
	# Excluimos al personaje para evitar colisiones de más
	shape_query.exclude = [character]
	
	# Y hacemos la query, lo que devuelve una lista de puntos si hubo
	# alguna colisión.
	var results: Array[Vector2] = space_state.collide_shape(shape_query, 4)
	
	# Ponemos un contador para evitar cuelgues en el while
	var count: int = 0
	var target_count: int = int(global_position.distance_to(final_point))
	
	# Chequeamos que haya habido colisiones (para evitar divisiones por 0)
	# y usamos un while para hacerlo N veces de ser necesario
	while !results.is_empty() && count < target_count:
		count += 1
		
		## Definimos un punto medio, inicializado en cero
		#var middle: Vector2 = Vector2.ZERO
		#
		## Sacamos el promedio
		#for result: Vector2 in results:
			#middle += result
		#middle /= results.size()
	
		# Y con ese promedio, que nos daría un punto neutro de colisión,
		# sacamos la Normal de la colisión resultante.
		var normal: Vector2 = -dash_raycast.target_position.normalized()
		
		# Y al final, si la Normal no es cero, aplicamos una traslación
		# para compensar por la colisión resultante.
		final_point += normal
		
		# Y volvemos a hacer la query
		shape_query.transform = global_transform.translated(to_local(final_point))
		results = space_state.collide_shape(shape_query, 4)
	
	# Cacheamos el vector que apunta al punto final
	var vector_to_final: Vector2 = final_point - character.global_position
	
	# Lo sumamos al vector de apuntado (así sigue "mirando" el arma hacia adelante)
	aim_point += vector_to_final
	
	# Le aplicamos una velocidad de lanzamiento y un impulso extra
	character.velocity = vector_to_final.normalized() * character.h_speed_limit
	_apply_cut_impulse()
	# Teleportamos al jugador
	character.global_position = final_point
	# Y le drenamos la stamina correspondiente
	character.sum_stamina(-stamina_drain[type])


# Aplica un impulso a la velocidad horizontal del personaje, tomando en
# consideración solamente el eje X de la normal del objetivo apuntado.
func _apply_cut_impulse() -> void:
	character.velocity.x += global_position.direction_to(aim_point).x * extra_impulse


# Al terminar las animaciones, entro en "RESET" para limpiar.
func _on_attacks_anim_animation_finished(_anim_name: StringName) -> void:
	attacks_anim.play(&"RESET")


# Si el corte detecta enemigos, aplica daño y un knockback.
func _on_cut_area_body_entered(body: Node2D) -> void:
	if body.has_method(&"notify_hit"):
		body.notify_hit(-cut_damage)
	if &"velocity" in body && body is Node2D:
		body.velocity += global_position.direction_to(aim_point) * cut_push
