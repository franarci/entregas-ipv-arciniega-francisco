extends Area2D

## Implementación de trigger genérico de eventos. Puede llamar a
## Nodes con argumentos establecidos en [class CallbackArguments].

## Una implementación más compleja con Timers podría permitir cosas como,
## por ejemplo, un sistema de cinemáticas, moviendo los parámetros
## de la Camera de forma custom en tiempos determinados e inmovilizando
## al Player.

@export var nodes_affected: Array[Node]
@export var callbacks: Array[CallbackArguments]


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node) -> void:
	for i in nodes_affected.size():
		var node: Node = nodes_affected[i]
		var callback_arguments: CallbackArguments = callbacks[i]
		
		if node.has_method(callback_arguments.callback_path):
			node.callv(
				callback_arguments.callback_path,
				callback_arguments.arguments
			)
		elif callback_arguments.callback_path in node && !callback_arguments.arguments.is_empty():
			node.set(
				callback_arguments.callback_path,
				callback_arguments.arguments[0]
			)
