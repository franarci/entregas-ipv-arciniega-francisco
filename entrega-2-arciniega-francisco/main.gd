extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Player.set_projectile_container(self)
	$Turret.set_values($Player, self)
