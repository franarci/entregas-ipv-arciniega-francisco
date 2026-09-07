extends Node

@export var turret_scene: PackedScene

func _ready() -> void:
	call_deferred("initialize")

func initialize() -> void:
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	for i in 3:
		var turret_instance: Node2D = turret_scene.instantiate()
		
		var turret_pos: Vector2 = Vector2(
			randf_range(visible_rect.position.x, visible_rect.end.x),
			randf_range(visible_rect.position.y + 30, 50)
		)
		
		add_child(turret_instance)
		turret_instance.initialize(turret_pos, self)
