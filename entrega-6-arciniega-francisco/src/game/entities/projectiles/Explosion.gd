extends Node2D

## Proyectil explosivo, daño alto en un area grande.
## Funciona como "proyectil" en interfaz, pero opera como un efecto
## de un solo uso, aplicado en un punto determinado con un
## Raycast dependiendo de dónde se este apuntando con el Mouse.

@onready var direction_raycast: RayCast2D = $DirectionRaycast
@onready var explosion_animation: AnimationPlayer = $ExplosionAnimation

@export var damage: int = 4.0
@export var push_force: float = 1000.0


func initialize(spawn_position: Vector2, _direction: Vector2) -> void:
	global_position = spawn_position
	_determine_end_point()
	explosion_animation.play(&"explosion")


func _determine_end_point() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	direction_raycast.target_position = direction_raycast.to_local(mouse_pos)
	direction_raycast.force_raycast_update()
	
	if direction_raycast.is_colliding():
		global_position = direction_raycast.get_collision_point()
	else:
		global_position = mouse_pos


func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()


func _on_ExplosionArea_body_entered(body: Node) -> void:
	if body.has_method(&"notify_hit"):
		body.notify_hit(-damage)
	if &"velocity" in body && body is Node2D:
		body.velocity += global_position.direction_to(body.global_position) * push_force
