extends Sprite2D

@onready var fire_position: Node2D = $FirePosition
@onready var fire_timer: Timer = $FireTimer

@export var projectile_scene: PackedScene

var player: Node2D
var projectile_container: Node

func initialize(turret_pos: Vector2, player: Node2D, projectile_container: Node) -> void:
	global_position = turret_pos
	self.player = player
	self.projectile_container = projectile_container
	fire_timer.connect("timeout", fire_at_player)
	fire_timer.start()

func fire_at_player() -> void:
	var proj_instance = projectile_scene.instantiate()
	proj_instance.initialize(
		projectile_container,
		fire_position.global_position,
		fire_position.global_position.direction_to(player.global_position)
	)
