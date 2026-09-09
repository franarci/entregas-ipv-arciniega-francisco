extends StaticBody2D

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer

@export var projectile_scene: PackedScene

var projectile_container: Node

var target: Node2D

func _ready() -> void:
	fire_timer.connect("timeout", fire_at_target)

func initialize(turret_pos: Vector2, p_projectile_container: Node) -> void:
	global_position = turret_pos
	self.projectile_container = p_projectile_container
	

func fire_at_target() -> void:
	var proj_instance = projectile_scene.instantiate()
	proj_instance.initialize(
		projectile_container,
		fire_position.global_position,
		fire_position.global_position.direction_to(target.global_position)
	)


func _on_detection_area_body_entered(body: Node2D) -> void:
	target = body
	fire_timer.start()


func _on_detection_area_body_exited(_body: Node2D) -> void:
	fire_timer.stop()

func notify_hit():
	print("Im turret and I'm hit")
	_remove.call_deferred()
func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()
