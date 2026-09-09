extends Sprite2D

@onready var lifetime_timer = $LifetimeTimer
@onready var hitbox = $Hitbox
@export var VELOCITY: float = 800.0
@export var MASK: int = 0

var direction:Vector2
func _ready():
	print("hitbox: ", hitbox)
func initialize(container, spawn_position:Vector2, p_direction:Vector2):
	if hitbox != null:
		hitbox.collision_mask = MASK
	container.add_child(self)
	self.direction = p_direction
	global_position = spawn_position
	lifetime_timer.connect("timeout", Callable(self, "_on_lifetime_timer_timeout"))
	lifetime_timer.start()

func _physics_process(delta):
	position += direction * VELOCITY * delta
	
	# Necesitamos que desaparezca en algun momento
	
	# Si está fuera de la pantalla
	var visible_rect:Rect2 = get_viewport().get_visible_rect()
	if !visible_rect.has_point(global_position):
		_remove()

# Si supero una cantidad de tiempo de vida
func _on_lifetime_timer_timeout():
	_remove()

func _remove():
	get_parent().remove_child(self)
	queue_free()
	


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("notify_hit"):
		body.notify_hit()
	hitbox.collision_mask = 0
	_remove.call_deferred()
