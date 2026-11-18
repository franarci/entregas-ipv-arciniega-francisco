@abstract
class_name TurretState extends AbstractState

var character: EnemyTurret


## Manejamos los eventos de detección de cuerpo aprovechando el polimorfismo
## del parámetro "values" para pasar el cuerpo detectado
func handle_event(event: StringName, ...values: Array) -> void:
	match event:
		&"body_entered":
			_handle_body_entered(values.front())
		&"body_exited":
			_handle_body_exited(values.front())
		&"hit":
			_handle_hit(values.front())
		&"hp_changed":
			_handle_hp_changed(values[0], values[1])


# Derivamos la detección del target que entra
func _handle_body_entered(body: Node) -> void:
	if character.target == null:
		character.target = body


# Derivamos la detección del target que sale
func _handle_body_exited(body: Node) -> void:
	if body == character.target:
		character.target = null


func _handle_hit(amount: int) -> void:
	character._sum_hp(amount)


func _handle_hp_changed(hp: int, _max_hp: int) -> void:
	if hp == 0:
		finished.emit(&"dead")
