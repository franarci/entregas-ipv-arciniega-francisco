@abstract
class_name AbstractWeapon extends Node2D

## Interfaz para un arma usable por el Player.
## Presenta al menos 3 tipos de ataque diferentes, mapeados a
## teclas diferentes, una variable de contenedor de proyectil,
## e interfaces para callbacks regulares.

## Junto al manager de armas se emula el patrón de State Machine,
## siendo esta interfaz un State.

enum ATT_TYPE {
	PRIMARY,
	SECONDARY,
	SPECIAL
}

@export var weapon_icon: Texture
@export var input_map: Dictionary = {
	"attack_weapon1": ATT_TYPE.PRIMARY,
	"attack_weapon2": ATT_TYPE.SECONDARY,
	"attack_weapon3": ATT_TYPE.SPECIAL
}

var projectile_container: Node


# Por default, enter y exit muestran y esconden el arma.
func enter() -> void:
	show()


func exit() -> void:
	hide()


@abstract
func update_weapon(delta: float, character: Node, can_attack: bool = true) -> void
