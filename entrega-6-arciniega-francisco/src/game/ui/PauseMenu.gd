extends Control

## Menú de pausa genérico, abierto utilizando la acción "pause_menu"
## (por default la tecla Esc).
@onready var options_menu: Control = $OptionsMenu

signal return_selected()
signal restart_selected()

func _ready() -> void:
	#return_selected.connect()
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") && !options_menu.visible:
		visible = !visible
		get_tree().paused = visible

func _on_resume_button_pressed() -> void:
	hide()
	get_tree().paused = false


func _on_return_button_pressed() -> void:
	return_selected.emit()


func _on_reset_button_pressed() -> void:
	restart_selected.emit()
