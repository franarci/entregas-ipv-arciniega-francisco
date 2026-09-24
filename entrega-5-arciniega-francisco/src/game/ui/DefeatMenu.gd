extends Control

## Menú de derrota genérico. Solo se presenta si detecta que
## el Player llegó a 0 de HP.

signal retry_selected()
signal return_selected()


func _ready() -> void:
	hide()
	GameState.current_player_changed.connect(_on_current_player_changed)


func _on_current_player_changed(player: Player) -> void:
	player.hp_changed.connect(_on_hp_changed)
	_on_hp_changed(player.hp, player.max_hp)


func _on_hp_changed(hp: int, _hp_max: int) -> void:
	if hp == 0:
		show()


func _on_retry_button_pressed() -> void:
	retry_selected.emit()


func _on_return_button_pressed() -> void:
	return_selected.emit()
