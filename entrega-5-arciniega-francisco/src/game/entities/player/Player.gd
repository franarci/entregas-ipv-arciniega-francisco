extends CharacterBody2D
class_name Player

# Señales que sirven para comunicar el estado del Player
# a los elementos conectados. Se puede utilizar tanto para
# comunicar estados a la State Machine (sin incluir código
# de la state machine directamente) como para comunicarse,
# por ejemplo, con el entorno del nivel.

## Señal que indica que el personaje fue golpeado
signal hit(amount: int)
## Señal que indica que el personaje fue curado
@warning_ignore("unused_signal")
signal healed(amount: int)
## Señal que indica cambio de estado en la salud del personaje
signal hp_changed(current_hp: int, max_hp: int)
signal mana_changed(current_mana, max_mana)
signal stamina_changed(current_stamina, max_stamina)
## Señal emitida al morir
@warning_ignore("unused_signal")
signal died()

@onready var weapon_manager: Node = $WeaponManager
@onready var body_animations: AnimationPlayer = $BodyAnimations
@onready var body_pivot: Node2D = $BodyPivot
@onready var body: Sprite2D = %Body
@onready var floor_raycasts: Array = $FloorRaycasts.get_children()

@export var acceleration: float = 3750.0 # Lo multiplicamos por delta, asi que es 60.0 / (1.0 / 60.0)
@export var h_speed_limit: float = 300.0
@export var jump_speed: int = 500
@export var friction_weight: float = 6.25 # Lo multiplicamos por delta, asi que es 0.1 / (1.0 / 60.0)
@export var gravity: float = 625.0 # Lo multiplicamos por delta, asi que es 10.0 / (1.0 / 60.0)
@export var push_force: float = 80.0

@export var max_hp: int = 10
var hp: int = max_hp

@export var max_mana: float = 5.0
var mana: float = max_mana

@export var mana_recovery_time: float = 5.0
@export var mana_recovery_delay: float = 1.0

@export var max_stamina: float = 10.0
var stamina: float = max_stamina

@export var stamina_recovery_time: float = 5.0
@export var stamina_recovery_delay: float = 0.5

var projectile_container: Node
var h_movement_direction: int = 0

## Flag de ayuda para saber identificar el estado de actividad
var dead: bool = false


func _ready() -> void:
	initialize()


func initialize(_projectile_container: Node = get_parent()) -> void:
	self.projectile_container = _projectile_container
	weapon_manager.projectile_container = projectile_container
	for weapon_scene in GameState.weapons_stash:
		add_weapon(weapon_scene)
	GameState.set_current_player(self)


# Interfaz para agregar un arma nueva, delega al WeaponManager.
func add_weapon(weapon_scene: PackedScene) -> void:
	weapon_manager.add_weapon(weapon_scene)


# El único elemento que queda abstraer de esta función
# es el manejo del salto. Esta parte del código no va a
# seguir formando parte del código del player, y, en su lugar
# lo migraremos al código del estado Jump correspondiente
func _process_input() -> void:
	# Jump Action
	var jump: bool = Input.is_action_just_pressed(&"jump")
	if jump && is_on_floor_raycasted():
		velocity.y -= jump_speed


# Se extrae el comportamiento de manejo del disparo del arma a
# una función para ser llamada apropiadamente desde la state machine
func _handle_weapon_actions(delta: float, can_attack: bool = true) -> void:
	weapon_manager.update_weapon(delta, self, can_attack)


# Hacemos lo mismo que con las acciones del arma, encapsulamos el
# comportamiento del handling del input horizontal. En este caso
# dividimos la aceleración y la desaceleración por separado porque
# ahora delegamos esa decisión a cada state.
func _handle_move_input(delta: float) -> void:
	h_movement_direction = int(
		Input.is_action_pressed(&"move_right")) - int(Input.is_action_pressed(&"move_left")
	)
	if h_movement_direction != 0:
		velocity.x = clamp(
			velocity.x + (h_movement_direction * acceleration * delta),
			-h_speed_limit,
			h_speed_limit
		)
		# Giramos el sprite dependiendo de a dónde nos movemos
		# 1 para derecha, -1 para izquierda, pero nunca 0
		body_pivot.scale.x = 1 - 2 * float(h_movement_direction < 0)


# Se extrae el comportamiento del manejo de la aplicación de fricción
# a una función para ser llamada apropiadamente desde cada state
func _handle_deacceleration(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, friction_weight * delta) if abs(velocity.x) > 1 else 0


# Se extrae el comportamiento de la aplicación de gravedad y movimiento
# a una función para ser llamada apropiadamente desde cada state
func _apply_movement(delta: float) -> void:
	# Gravity
	# Multiplicamos por delta para que sea independiente del framerate
	velocity.y += gravity * delta
	
	# Basado en https://youtu.be/SJuScDavstM
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		if collision.get_collider() is RigidBody2D:
			var collision_normal: Vector2 = collision.get_normal()
			var velocity_alignment: float = float(
				collision_normal.dot(-velocity.normalized()) > 0.0
			)
			collision.get_collider().apply_central_impulse(
				-collision_normal.slerp(-velocity.normalized(), 0.5) * push_force * velocity_alignment
			)
	
	move_and_slide()


## Función is_on_floor() custom que agrega chequeo de raycasts
## para expandir la ventana de chequeo de piso
func is_on_floor_raycasted() -> bool:
	var is_colliding: bool = is_on_floor()
	for raycast in floor_raycasts:
		## Al tener deshabilitados los raycasts por default
		## ya que queremos que solamente se procesen en esta
		## función, debemos forzar una actualización
		raycast.force_raycast_update()
		is_colliding = is_colliding || raycast.is_colliding()
	return is_colliding


# Esta función ya no llama directamente a remove, sino que deriva
# el handleo a la state machine emitiendo una señal. Esto es para
# los casos de estados en los cuales no se manejan hits
func notify_hit(amount: int = 1) -> void:
	hit.emit(amount)


# Y acá se maneja la salud.
func sum_hp(amount: int) -> void:
	hp = clamp(hp + amount, 0, max_hp)
	hp_changed.emit(hp, max_hp)
	print("hp_changed %s %s" % [hp, max_hp])


var mana_regen_tween: Tween

func sum_mana(amount: float) -> void:
	_update_passive_prop(
		clamp(mana + amount, 0.0, max_mana),
		max_mana,
		&"mana",
		mana_changed
	)
	if mana < max_mana:
		if mana_regen_tween:
			mana_regen_tween.kill()
		mana_regen_tween = create_tween()
		var duration: float = (max_mana - mana) * mana_recovery_time / max_mana
		mana_regen_tween.tween_method(
			_update_passive_prop.bind(max_mana, &"mana", stamina_changed),
			mana, max_mana, duration,
		).set_delay(mana_recovery_delay)


var stamina_regen_tween: Tween

func sum_stamina(amount: float) -> void:
	_update_passive_prop(
		clamp(stamina + amount, 0.0, max_stamina),
		max_stamina,
		&"stamina",
		stamina_changed
	)
	if stamina < max_stamina:
		if stamina_regen_tween:
			stamina_regen_tween.kill()
		stamina_regen_tween = create_tween()
		var duration: float = (max_stamina - stamina) * stamina_recovery_time / max_stamina
		stamina_regen_tween.tween_method(
			_update_passive_prop.bind(max_stamina, &"stamina", stamina_changed),
			stamina,
			max_stamina,
			duration
		).set_delay(stamina_recovery_delay)


func _update_passive_prop(
	amount: float,
	max_amount: float,
	property: StringName,
	updated_signal: Signal
) -> void:
	set(property, amount)
	updated_signal.emit(amount, max_amount)



# El llamado a remove final
func _remove() -> void:
	set_physics_process(false)
	collision_layer = 0


# Wrapper sobre el llamado a animación para tener un solo punto de entrada controlable
# (en el caso de que necesitemos expandir la lógica o debuggear, por ejemplo)
func _play_animation(animation: StringName) -> void:
	if body_animations.has_animation(animation):
		body_animations.play(animation)
