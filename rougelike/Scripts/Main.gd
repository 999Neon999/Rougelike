extends Node2D

var room_scene = preload("res://Scenes/Room.tscn")
var player_scene = preload("res://Scenes/Player.tscn")
var rooms: Dictionary = {}  # {Vector2i: Room instance}
var current_room_pos: Vector2i = Vector2i(0, 0)
var player: CharacterBody2D = null  # Track the player instance

func _ready():
	print("Main scene initializing...")
	print("LevelManager rooms before placing: ", LevelManager.rooms.keys())
	place_rooms()
	if rooms.is_empty():
		print("Error: No rooms were placed")
		return
	spawn_player()
	update_doors()
	if player:
		player.connect("door_transition", Callable(self, "_on_door_transition"))
	else:
		print("Error: Player node not found")

func place_rooms():
	for pos in LevelManager.rooms.keys():
		var room = room_scene.instantiate()
		room.grid_pos = pos
		room.room_type = LevelManager.rooms[pos].type
		room.position = Vector2(pos.x * 640, pos.y * 360)  # Room size: 640x360
		rooms[pos] = room
		add_child(room)
		# Hide all rooms initially
		room.set_active(false)
		print("Placed room at ", pos, " type ", room.room_type, " position ", room.position, " Visible: ", room.visible)
	# Show only the starting room
	if rooms.has(Vector2i(0, 0)):
		rooms[Vector2i(0, 0)].set_active(true)
		print("Start room (0, 0) made visible")

func update_doors():
	for pos in rooms.keys():
		var room = rooms[pos]
		var directions = ["north", "south", "east", "west"]
		for dir in directions:
			var door = room.get_node_or_null("Door_" + dir)
			if door:
				door.collision_layer = 2
				door.collision_mask = 0
				var neighbor_pos = get_neighbor_pos(pos, dir)
				if not LevelManager.rooms.has(neighbor_pos):
					door.get_node("CollisionShape2D").disabled = true
					print("Disabled door at ", pos, " for ", dir, " (no neighbor at ", neighbor_pos, ")")
				else:
					var door_collision = door.get_node("CollisionShape2D")
					print("Door at ", pos, " for ", dir, " (neighbor at ", neighbor_pos, ") Enabled: ", !door_collision.disabled, " Door layer: ", door.collision_layer, " Mask: ", door.collision_mask)

func get_neighbor_pos(pos: Vector2i, direction: String) -> Vector2i:
	match direction:
		"north": return pos + Vector2i(0, -1)
		"south": return pos + Vector2i(0, 1)
		"east": return pos + Vector2i(1, 0)
		"west": return pos + Vector2i(-1, 0)
	return pos

func spawn_player():
	if not rooms.has(Vector2i(0, 0)):
		print("Error: Start room (0, 0) not found in rooms: ", rooms.keys())
		return
	var existing_players = get_tree().get_nodes_in_group("player")
	for p in existing_players:
		p.queue_free()
		print("Removed existing player: ", p)
	player = player_scene.instantiate()
	player.position = rooms[Vector2i(0, 0)].position + Vector2(640, 360)  # Center of the room (640x360)
	player.current_room = Vector2i(0, 0)
	add_child(player)
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.queue_free()
		print("Removed Camera2D from player")
	player.add_to_group("player")
	print("Spawned player at ", player.position)

func _on_door_transition(direction: String, room_pos: Vector2i):
	if not player or player.current_room != room_pos:
		print("Error: Invalid player or room mismatch. Player: ", player, " Room: ", room_pos)
		return
	var target_pos = get_neighbor_pos(room_pos, direction)
	if LevelManager.rooms.has(target_pos):
		var visible_rooms = []
		for pos in rooms.keys():
			if rooms[pos].visible:
				visible_rooms.append(pos)
		print("Visible rooms before transition: ", visible_rooms)
		for pos in rooms.keys():
			rooms[pos].set_active(false)
			print("Hid room at ", pos, " Visible: ", rooms[pos].visible)
		player.current_room = target_pos
		current_room_pos = target_pos
		var target_room = rooms[target_pos]
		var fade = CanvasLayer.new()
		var color_rect = ColorRect.new()
		color_rect.size = get_viewport().size
		color_rect.color = Color(0, 0, 0, 0)
		color_rect.position = Vector2.ZERO
		fade.add_child(color_rect)
		add_child(fade)
		var tween = create_tween()
		if tween and tween.is_valid():
			tween.tween_property(color_rect, "color:a", 1.0, 0.25).set_trans(Tween.TRANS_LINEAR)
		await get_tree().create_timer(0.5).timeout
		# Position player near the opposite door
		var player_offset: Vector2
		match direction:
			"north": player_offset = Vector2(638, 550)  # Enter from north, spawn near south door
			"south": player_offset = Vector2(637, 100)   # Enter from south, spawn near north door
			"east": player_offset = Vector2(1100, 360)    # Enter from east, spawn near west door
			"west": player_offset = Vector2(150, 351)   # Enter from west, spawn near east door
		player.position = target_room.position + player_offset
		target_room.set_active(true)
		print("Showed room at ", target_pos, " Visible: ", target_room.visible)
		if tween and tween.is_valid():
			tween.tween_property(color_rect, "color:a", 0.0, 0.25).set_trans(Tween.TRANS_LINEAR)
		await tween.finished if tween and tween.is_valid() else get_tree().create_timer(0.25).timeout
		fade.queue_free()
		print("Transitioned to room ", target_pos, " at ", target_room.position, " player at ", player.position)
