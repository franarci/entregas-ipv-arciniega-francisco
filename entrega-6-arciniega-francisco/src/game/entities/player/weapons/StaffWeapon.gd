extends AbstractWeapon

## Abstracción del arma estilo cañon vista anteriormente. Implementa la
## interfaz de AbstractWeapon y expande los ataques a 2 más.
## Los ataques ahora consumen Mana, y son dependientes de la cantidad
## de Mana para ejecutarse.

## Ataque 1 - Bolt mágico, daño decente, consumo medio de Mana.
## Ataque 2 - Empuje de viento, daño bajo, knockback fuerte, poco consumo de Mana.
## Ataque 3 - Expuroshion, daño alto, fuerte consumo de Mana.

@onready var weapon_tip: Node2D = $WeaponTip
@onready var fx_anim: AnimationPlayer = $FXAnim

@export var projectile_scenes: Array[PackedScene]
@export var mana_drain: PackedFloat32Array = PackedFloat32Array([2.0, 1.0, 5.0])

@export var anim_map: Dictionary[AbstractWeapon.ATT_TYPE, StringName] = {
	ATT_TYPE.PRIMARY: &"bolt",
	ATT_TYPE.SECONDARY: &"wind",
	ATT_TYPE.SPECIAL: &"fire"
}

var aim_point: Vector2
var fire_tween: Tween

var character: Player


func enter() -> void:
	super.enter()
	fx_anim.play("RESET")
	await fx_anim.animation_finished
	rotation = deg_to_rad(-90)


func exit() -> void:
	super.exit()
	if fire_tween:
		fire_tween.kill()
	fx_anim.play("RESET")
	await fx_anim.animation_finished
	rotation = deg_to_rad(-90)


func update_weapon(_delta: float, p_character: Node, can_attack: bool = true) -> void:
	if fx_anim.is_playing():
		## Acá solo me mantengo apuntando si tengo habilitada esa función.
		## Esto es como corrección de apuntado para compensar por el delay
		## aplicado por la animación de disparo.
		rotation = (aim_point - global_position).angle()
	elif can_attack:
		## Y sino, manejo el disparo acorde al drenado de Mana que corresponde.
		for input in input_map.keys():
			if (
				Input.is_action_just_pressed(input) &&
				p_character.mana >= mana_drain[input_map[input]]
			):
				attack(input_map[input])
				self.character = p_character


func attack(type: int) -> void:
	## Mato al tween antes de disparar para que no me cambie la rotación
	if fire_tween != null:
		fire_tween.kill()
	## No disparo de inmediato, sino que delego a una animación de disparo
	fx_anim.play(anim_map[type])
	aim_point = get_global_mouse_position()


## La animación de disparo llama a esta función que va a ser la que instancie
## el proyectil
func _fire(type: int) -> void:
	var projectile_instance: Node = projectile_scenes[type].instantiate()
	projectile_container.add_child(projectile_instance)
	projectile_instance.initialize(
		weapon_tip.global_position,
		global_position.direction_to(weapon_tip.global_position))
	
	character.sum_mana(-mana_drain[type])
	## Y por último animo el retorno a la posición de inicio del arma
	fire_tween = create_tween()
	
	## Cálculo del demonio, podría haber sido mucho más sencillo utilizando
	## vectores y sacando los ángulos circulares.
	## Lo que hace es toma el ángulo relativo más cercano, ya que después de cierto
	## punto, en vez de rotar correctamente hacia arriba, da toda la vuelta.
#	var final_angle: float = deg2rad(-90.0 + 360.0 * float(rotation > deg2rad(90)))
	
	## Me enculé y lo hice de esta manera. Parece chino también, pero básicamente
	## toma un vector con rotación 0 (los radianes SIEMPRE toman como rotación 0
	## mirar a la izquierda, osea, (1, 0)) y le aplica la rotación actual, le pide el ángulo
	## hacia la dirección que queremos que vaya, y luego se lo suma a la rotación actual.
	var final_angle: float = rotation + Vector2.LEFT.rotated(rotation).angle_to(Vector2.DOWN)
	
	## Y acá se anima programáticamente utilizando el ángulo actual del arma hacia
	## el ángulo final al que debe rotar.
	fire_tween.tween_property(self, "rotation", final_angle, 0.5).set_delay(0.5)
