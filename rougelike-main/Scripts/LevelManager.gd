extends Node

var rooms: Dictionary = {}  # {Vector2i: {type: String}}
var dead_ends: Array[Vector2i] = []

func save_level():
	print("Level saved: ", rooms.keys())

func load_level() -> bool:
	return false  # For now, always generate a new level
