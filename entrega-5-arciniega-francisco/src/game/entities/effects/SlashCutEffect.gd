extends Node2D

## Animación simple de corte con Dash. Implementa una interfaz similar
## a la de un proyectil, pero sin hacer daño por si mismo.
## Utiliza un Line2D para la línea de corte, y dos pivotes rotados
## con Sprites animados mediante un AnimationPlayer para los
## efectos en orígen y destino.

@onready var dash_animation: AnimationPlayer = $DashAnimation
@onready var start_pivot: Node2D = $StartPivot
@onready var end_pivot: Node2D = $EndPivot
@onready var cut_line: Line2D = $CutLine


func initialize(start_position: Vector2, end_position: Vector2, direction: Vector2) -> void:
	global_position = start_position
	start_pivot.global_position = start_position
	end_pivot.global_position = end_position
	start_pivot.rotation = direction.angle()
	end_pivot.rotation = start_pivot.rotation
	cut_line.points = [cut_line.to_local(start_position), cut_line.to_local(end_position)]
	dash_animation.play(&"dash")


func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()
