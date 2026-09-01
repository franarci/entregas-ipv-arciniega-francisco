extends Sprite2D

#var projectile_scene:PackedScene = preload("res://entities/player/projectile.tscn")
@onready var fire_position:Marker2D = $FirePosition
@export var projectile_scene:PackedScene

var projectile_container: Node

func _on_projectile_delete_requested(projectile):
	# Eliminamos el remove_child() que fallaba.
	# Verificamos que el proyectil sea válido antes de borrarlo por seguridad.
	if is_instance_valid(projectile):
		projectile.queue_free() 

func fire():
	var projectile_instance:Projectile = projectile_scene.instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.set_starting_values(fire_position.global_position,(fire_position.global_position - global_position).normalized())
	
	projectile_instance.delete_requested.connect(_on_projectile_delete_requested.bind(projectile_instance))
