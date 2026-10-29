extends Node2D

## Escena genérica portadora de armas (Le revocaron la licencia /j)
## Puede presentar el ícono del arma y almacena la escena del arma
## para cedersela al Player al agarrarlo.

## Puede extenderse para almacenar, por ejemplo, el tutorial que
## corresponde al arma que contiene. Podría obtener la información
## del tutorial mediante una variable export o pedirsela al arma.

@onready var weapon_icon: TextureRect = $"%WeaponIcon"
@onready var pickup_animation: AnimationPlayer = $PickupAnimation

@export var weapon_scene: PackedScene

var picked: bool = false


func _ready() -> void:
	## Instanciamos una vez el arma para recuperar la información
	## que necesitamos al arrancar.
	var weapon: AbstractWeapon = weapon_scene.instantiate()
	weapon_icon.texture = weapon.weapon_icon
	weapon.queue_free()
	pickup_animation.play("idle")


## Al entrar en contacto con el Player, le agregamos la escena del
## arma, y notificamos al GameState que se levantó un arma nueva.
func _on_PickupArea_body_entered(body: Node) -> void:
	if body is Player && !picked:
		body.add_weapon(weapon_scene)
		GameState.notify_weapon_picked(weapon_scene)
		weapon_icon.hide()
		picked = true
	
