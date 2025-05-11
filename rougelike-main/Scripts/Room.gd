extends Node2D

var grid_pos: Vector2i
var room_type: String = "normal"
var neighbor_config: String = "0N_None"  # Default: no neighbors
var sprite: Sprite2D
var camera: Camera2D

func _ready():
	sprite = $Sprite2D
	camera = $Camera2D
	if camera:
		camera.enabled = false
	update_color()
	# Load texture based on neighbor configuration
	var texture_path = "res://Assets/Rooms/" + neighbor_config + ".png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		print("Loaded texture for room at ", grid_pos, ": ", texture_path)
	else:
		print("Warning: Texture not found for ", neighbor_config, " at ", grid_pos, " (path: ", texture_path, ")")
	# Debug doors
	var directions = ["north", "south", "east", "west"]
	for dir in directions:
		var door = get_node_or_null("Door_" + dir)
		if door:
			print("Door found at ", grid_pos, " for direction ", dir)
		else:
			print("Warning: Door_" + dir + " not found at ", grid_pos)

func update_color():
	if sprite:
		match room_type:
			"start": sprite.modulate = Color(0, 1, 0)
			"normal": sprite.modulate = Color(1, 1, 1)
			"boss": sprite.modulate = Color(1, 0, 0)
			"treasure": sprite.modulate = Color(1, 1, 0)
			"shop": sprite.modulate = Color(0, 0, 1)


func set_active(is_active: bool):
	visible = is_active
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.visible = is_active
	if camera:
		camera.enabled = is_active
		print("Camera at ", grid_pos, " enabled: ", camera.enabled)
	var directions = ["north", "south", "east", "west"]
	for dir in directions:
		var door = get_node_or_null("Door_" + dir)
		if door:
			var door_collision = door.get_node_or_null("CollisionShape2D")
			if door_collision:
				door_collision.disabled = !is_active
				print("Door_" + dir + " at ", grid_pos, " collision disabled: ", door_collision.disabled)
			else:
				print("Warning: CollisionShape2D not found for Door_" + dir + " at ", grid_pos)
