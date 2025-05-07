extends Area2D

signal door_entered(body)

func _ready():
	add_to_group("doors")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		emit_signal("door_entered", body)
