extends PlayerState

@export var jumps_limit: int = 1

var jumps: int = 0


func enter() -> void:
	character.velocity.y = -character.jump_speed
	character._play_animation(&"jump")


func exit() -> void:
	jumps = 0


func handle_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed(&"dash") &&
		character.h_movement_direction != 0
	):
		finished.emit(&"dash")
	elif event.is_action_pressed(&"jump") && jumps < jumps_limit:
		jumps += 1
		character.velocity.y = -character.jump_speed
		character._play_animation(&"jump")


func update(delta: float) -> void:
	character._handle_weapon_actions(delta)
	character._handle_move_input(delta)
	if character.h_movement_direction == 0:
		character._handle_deacceleration(delta)
	character._apply_movement(delta)
	if character.is_on_floor():
		if character.h_movement_direction == 0:
			finished.emit(&"idle")
		else:
			finished.emit(&"walk")
	else:
		if character.velocity.y > 0:
			character._play_animation(&"fall")
		else:
			character._play_animation(&"jump")


# En este callback manejamos, por el momento, solo los impactos
func handle_event(event: StringName, ...values: Array) -> void:
	match event:
		&"hit", &"healed":
			character.sum_hp(values.front())
		&"hp_changed":
			if values.front() == 0:
				finished.emit(&"dead")



func _on_animation_finished(_anim_name: StringName) -> void:
	return
