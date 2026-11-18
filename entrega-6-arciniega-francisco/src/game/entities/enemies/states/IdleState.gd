## Este estado hereda de un State intermedio llamado TurretState
## que extiende la interfaz de State con comportamientos específicos
## (se puede abrir el script con Ctrl+click)
extends TurretState

# Usamos un Timer para controlar cuánto tiempo queda in Idle
@export var idle_timer: Timer


func enter() -> void:
	# Seteamos la velocidad a (0,0) para que no se mueva
	character.velocity = Vector2.ZERO
	
	# Chequeamos si debe estar con la guardia en alto o no
	if character.target != null:
		character._play_animation(&"idle_alert")
	else:
		character._play_animation(&"idle")
	# Iniciamos el Timer para salir del estado
	idle_timer.start()


func update(_delta: float) -> void:
	# Aplicamos movimiento, para que siga "colisionando" con el mundo
	character.move_and_slide()
	
	# Y si notamos que puede "ver" al objetivo, entramos en Alert
	if character._can_see_target():
		finished.emit(&"alert")


# Al salir, nos aseguramos de limpiar el timer de Idle
func exit() -> void:
	idle_timer.stop()


# Cuando termina el timer, transiciona al estado Walk
func _on_idle_timer_timeout() -> void:
	finished.emit(&"walk")


func _handle_body_entered(body: Node) -> void:
	super._handle_body_entered(body)
	
	## No se ejecuta directamente el "idle_alert", sino que se ejecuta una
	## animación de transición
	character._play_animation(&"alert")


func _handle_body_exited(body: Node) -> void:
	super._handle_body_exited(body)
	
	## No se ejecuta directamente el "idle", sino que se ejecuta una
	## animación de transición
	character._play_animation(&"go_normal")


# Manejamos la transicion de animaciones "intermedias" a animaciones finales
func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"alert":
			character._play_animation(&"idle_alert")
		&"go_normal":
			character._play_animation(&"idle")


func handle_input(_event: InputEvent) -> void:
	return
