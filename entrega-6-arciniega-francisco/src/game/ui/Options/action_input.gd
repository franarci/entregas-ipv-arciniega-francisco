@tool
extends PanelContainer

@onready var input: Label = $HBoxContainer/PanelContainer/Input
@onready var action: Label = $HBoxContainer/Action

@export var action_input: String:
	get:
		return action_input
	set(value):
		action_input = value
		if Engine.is_editor_hint() && has_node("$HBoxContainer/PanelContainer/Input"):
			$HBoxContainer/PanelContainer/Input.text = value
@export var action_name: String:
	get:
		return action_name
	set(value):
		action_name = value
		if Engine.is_editor_hint() && has_node("$HBoxContainer/Action"):
			$HBoxContainer/Action.text = value


func _ready() -> void:
	input.text = action_input
	action.text = action_name
