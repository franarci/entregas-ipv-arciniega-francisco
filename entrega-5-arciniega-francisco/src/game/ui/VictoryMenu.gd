extends Control

## Menú de victoria genérico. Solo se presenta si se levanta la signal
## de "level_won" en GameState.

signal next_selected()
signal return_selected()


func _ready() -> void:
	hide()
	GameState.level_won.connect(_on_level_won)


func _on_level_won() -> void:
	show()


func _on_next_button_pressed() -> void:
	next_selected.emit()


func _on_return_button_pressed() -> void:
	return_selected.emit()
