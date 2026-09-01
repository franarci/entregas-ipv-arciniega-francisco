extends Sprite2D

@export var projectile_scene:PackedScene

@onready var fire_position:Marker2D = $FirePosition

var projectile_container:Node

var player

func set_values(p_player, container):
	self.player = p_player
	self.projectile_container = container
	$Timer.start()

func _on_timer_timeout() -> void:
	fire()
func _on_projectile_delete_requested(projectile):
	# Eliminamos el remove_child() que fallaba.
	# Verificamos que el proyectil sea válido antes de borrarlo por seguridad.
	if is_instance_valid(projectile):
		projectile.queue_free() 

func fire():
	var projectile:Projectile = projectile_scene.instantiate()
	projectile_container.add_child(projectile)
	projectile.set_starting_values(fire_position.global_position, (player.global_position - fire_position.global_position).normalized())
	projectile.delete_requested.connect(_on_projectile_delete_requested.bind(projectile))
