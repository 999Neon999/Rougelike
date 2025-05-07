extends Node2D

var grid_pos: Vector2i
var room_type: String = "normal"
var sprite: Sprite2D
var camera: Camera2D

func _ready():
	sprite = $Sprite2D
	camera = $Camera2D
	if camera:
		camera.enabled = false  # Ensure initially disabled
	update_color()

func update_color():
	if sprite:
		match room_type:
			"start": sprite.modulate = Color(0, 1, 0)
			"normal": sprite.modulate = Color(1, 1, 1)
			"boss": sprite.modulate = Color(1, 0, 0)
			"treasure": sprite.modulate = Color(1, 1, 0)
			"shop": sprite.modulate = Color(0, 0, 1)
		var icon = $Icon
		if icon:
			icon.visible = true
			print("Icon enabled at ", grid_pos)
		else:
			print("Icon node not found at ", grid_pos)

func set_active(is_active: bool):
	visible = is_active
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.visible = is_active
	# Enable/disable camera
	if camera:
		camera.enabled = is_active
		print("Camera at ", grid_pos, " enabled: ", camera.enabled)
	# Disable/enable doors to prevent detection when invisible
	var directions = ["north", "south", "east", "west"]
	for dir in directions:
		var door = get_node_or_null("Door_" + dir)
		if door:
			var door_collision = door.get_node_or_null("CollisionShape2D")
			if door_collision:
				door_collision.disabled = !is_active
