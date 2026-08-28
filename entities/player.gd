extends Sprite2D

@export var speed:float

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction:int = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")) # The player's movement vector.
	#if Input.is_action_pressed("move_left"):
		#direction = -1
	#if Input.is_action_pressed("move_right"):
		#direction = 1
	
	position.x += direction * speed * delta

	
