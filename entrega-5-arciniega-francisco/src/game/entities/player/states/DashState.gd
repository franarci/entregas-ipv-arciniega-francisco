extends PlayerState

@onready var dash_cooldown_timer: Timer = $DashCooldown

@export var dash_stamina_cost: float = 2.0
@export var dash_time: float = 1.0
@export var speed_multiplier: float = 1.0
@export var dash_cooldown: float = 1.0
@export var dash_cooldown_color: Color

var dash_timer: Timer


func _ready() -> void:
	dash_timer = Timer.new()
	add_child(dash_timer)
	dash_timer.one_shot = true
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	set_process(false)


func _process(_delta: float) -> void:
	var time_left: float = dash_cooldown_timer.time_left
	character.body.self_modulate = lerp(Color.WHITE, dash_cooldown_color, time_left / dash_cooldown)
	if time_left == 0:
		set_process(false)


func enter() -> void:
	if  !dash_cooldown_timer.is_stopped() || character.stamina < dash_stamina_cost:
		finished.emit(&"walk")
	else:
		dash_timer.start(dash_time)
		character.sum_stamina(-dash_stamina_cost)
		character._play_animation(&"dash")
		dash_cooldown_timer.start(dash_cooldown)
		set_process(true)


func exit() -> void:
	dash_timer.stop()


func update(delta: float) -> void:
	character._handle_weapon_actions(delta)
	character.velocity.x = clamp(
		character.velocity.x + (character.h_movement_direction * character.acceleration * speed_multiplier * delta),
		-character.h_speed_limit * speed_multiplier,
		character.h_speed_limit * speed_multiplier
	)
	character._apply_movement(delta)


func _on_dash_timer_timeout() -> void:
	character._handle_move_input(get_physics_process_delta_time())
	if character.h_movement_direction == 0:
		finished.emit(&"idle")
	else:
		finished.emit(&"walk")


# En este callback manejamos, por el momento, solo los impactos
func handle_event(event: StringName, ...values: Array) -> void:
	match event:
		&"hit", &"healed":
			character.sum_hp(values.front())
		&"hp_changed":
			if values.front() == 0:
				finished.emit(&"dead")


func handle_input(_event: InputEvent) -> void:
	return


func _on_animation_finished(_anim_name: StringName) -> void:
	return
