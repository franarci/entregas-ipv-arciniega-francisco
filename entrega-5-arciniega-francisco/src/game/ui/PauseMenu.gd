extends Control

## Menú de pausa genérico, abierto utilizando la acción "pause_menu"
## (por default la tecla Esc).


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause_menu"):
		visible = !visible


func _on_resume_button_pressed() -> void:
	hide()
