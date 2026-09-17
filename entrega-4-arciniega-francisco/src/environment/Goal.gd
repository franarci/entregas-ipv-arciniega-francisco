extends Area2D

@onready var portal: AnimatedSprite2D = $Portal

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(_body: Node) -> void:
	portal.play("Enter")
	print("You win!")
