extends Node2D

## Manager de las armas actuales del Player. Se encarga de delegar
## callbacks de update, agregar armas, setear actuales y cambiar entre ellas.

## El patrón usado es un State Machine, siendo el Manager la
## Máquina de Estados y las armas los States.

var projectile_container: Node : set = _set_projectile_container

var existing_weapons: Array = []
var weapons_list: Array = []
var current_weapon: AbstractWeapon


## Recibe el agregado del arma, revisa que no sea duplicado y
## realiza la inicialización de manera segura con call_deferred
func add_weapon(weapon_scene: PackedScene) -> void:
	if existing_weapons.has(weapon_scene):
		return
	existing_weapons.push_back(weapon_scene)
	_add_weapon.call_deferred(weapon_scene)


## Función que instancia, inicializa y agrega el arma nueva a
## la lista de armas, y la setea como actual en caso de
## no haber un arma activa.
func _add_weapon(weapon_scene: PackedScene) -> void:
	var weapon: AbstractWeapon = weapon_scene.instantiate()
	add_child(weapon)
	weapons_list.push_back(weapon)
	weapon.projectile_container = projectile_container
	if current_weapon == null:
		_set_weapon_as_current(weapon)
	else:
		weapon.hide()


## Setea un nuevo contenedor de proyectiles a todas las armas
## que esten agregadas.
func _set_projectile_container(container: Node) -> void:
	projectile_container = container
	for weapon in weapons_list:
		weapon.projectile_container = projectile_container


## Callback regular de actualización del arma. Se encarga de rotar
## de armas en caso de que se llame con los botones correspondientes.
func update_weapon(delta: float, character: Node, can_attack: bool = true) -> void:
	if current_weapon:
		current_weapon.update_weapon(delta, character, can_attack)
		if Input.is_action_just_released(&"weapon_next"):
			_switch_next_weapon()
		elif Input.is_action_just_released(&"weapon_prev"):
			_switch_prev_weapon()


## Switches genéricos de armas para determinar el ID del arma
## siguiente o anterior
func _switch_next_weapon() -> void:
	if weapons_list.size() > 1:
		var current: int = weapons_list.find(current_weapon)
		var next: int = (current + 1) % weapons_list.size()
		_set_weapon_as_current(weapons_list[next])


func _switch_prev_weapon() -> void:
	if weapons_list.size() > 1:
		var current: int = weapons_list.find(current_weapon)
		var next: int = (current - 1 + (weapons_list.size() * int(current == 0))) % weapons_list.size()
		_set_weapon_as_current(weapons_list[next])


## Función que setea el arma actual. Observar la implementación
## de la interfaz de State Machine vista en el controller del Player.
func _set_weapon_as_current(weapon: AbstractWeapon) -> void:
	if current_weapon:
		current_weapon.exit()
	current_weapon = weapon
	current_weapon.enter()
