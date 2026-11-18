extends PlayerState


# Al entrar se activa primero la animación "walk"
func enter() -> void:
	character._play_looping_audio(character.walk_sfx)
	character._play_animation(&"walk")


func exit() -> void:
	character._stop_looping_audio()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump"):
		finished.emit(&"jump")
	elif event.is_action_pressed(&"dash"):
		finished.emit(&"dash")


# En esta función vamos a manejar las acciones apropiadas para este estado
func update(delta: float) -> void:
	# Vamos a querer que se pueda disparar
	character._handle_weapon_actions(delta)
	
	# Vamos a manejar los inputs de movimiento
	character._handle_move_input(delta)
	# Aplicar ese movimiento, sin desacelerar
	character._apply_movement(delta)
	if character.is_on_floor() and character.h_movement_direction != 0:
		character._play_looping_audio(character.walk_sfx)
	else:
		character._stop_looping_audio()
	
	# Y luego chequeamos si se quedó quieto el personaje
	if character.h_movement_direction == 0:
		# Y cambiamos el estado a idle
		finished.emit(&"idle")
	else:
		# O aplicamos la animación que corresponde
		if character.is_on_floor():
			character._play_animation(&"walk")
		else:
			if character.velocity.y > 0:
				character._play_animation(&"fall")
			else:
				character._play_animation(&"jump")


func _on_animation_finished(_anim_name: StringName) -> void:
	return


# En este callback manejamos, por el momento, solo los impactos
func handle_event(event: StringName, ...values: Array) -> void:
	match event:
		&"hit", &"healed":
			character.sum_hp(values.front())
		&"hp_changed":
			if values.front() == 0:
				finished.emit(&"dead")
