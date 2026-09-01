extends Sprite2D
class_name Projectile

signal delete_requested(projectile)

var direction:Vector2
@export var speed:float
func _ready():
	set_process(false)
	#$Timer.connect("timeout", self, "on_timer_timeout")
	
func set_starting_values(starting_position:Vector2, p_direction:Vector2):
	global_position = starting_position
	self.direction = p_direction
	$Timer.start()
	set_process(true)
	
func _physics_process(delta: float):
	position += direction * speed *delta
	

func _on_timer_timeout() -> void:
	delete_requested.emit()
