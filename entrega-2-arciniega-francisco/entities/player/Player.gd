extends Sprite2D

@onready var cannon = $Cannon

@export var speed:float #Pixeles

var projectile_container:Node

func set_projectile_container(container:Node):
	cannon.projectile_container=container
	projectile_container=container
	
func _physics_process(delta):
	# Manera básica
	#var direction:int = 0
	#if Input.is_action_pressed("move_left"):
		#direction = -1
	#elif Input.is_action_pressed("move_right"):
		#direction = 1
	
	#position.x += direction * speed * delta
	
#	manera compleja de 'apuntar al mouse'
	#var mouse_position:Vector2 = get_global_mouse_position()
	#var origin:Vector2 = global_position
	#var direction_vector:Vector2 = mouse_position - origin
	#cannon.rotation = direction_vector.angle()
	
	
	# Manera optimizada
	var direction_optimized:int = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	
	# Manera rapida de 'apuntar al mouse'
	cannon.look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("fire"):
		cannon.fire()
	
	position.x += direction_optimized * speed * delta
