extends Node

var grid_size: Vector2i = Vector2i(16, 16)
var room_count: int

func _ready():
	room_count = randi_range(8, 10)
	print("Generating dungeon layout...")
	print("Target room count: ", room_count)
	if not LevelManager.load_level():
		generate_floor()
		LevelManager.save_level()

func generate_floor():
	LevelManager.rooms.clear()
	LevelManager.dead_ends.clear()
	
	var start_pos = Vector2i(0, 0)
	add_room(start_pos, "start")
	print("Placed start room at ", start_pos)
	
	var rooms_to_place = max(5, room_count - 3)
	var candidates = get_neighbors(start_pos)
	var start_neighbors = 2 if randf() < 0.75 else 3
	var placed_neighbors = 0
	print("Initial candidates: ", candidates, " target start neighbors: ", start_neighbors)
	
	while rooms_to_place > 0 and candidates.size() > 0:
		var pos = candidates[randi() % candidates.size()]
		if can_place_room(pos):
			var room_type = "normal"
			if is_neighbor_of_start(pos, start_pos) and placed_neighbors < start_neighbors:
				placed_neighbors += 1
			add_room(pos, room_type)
			rooms_to_place -= 1
			candidates.append_array(get_neighbors(pos))
			print("Placed room at ", pos, " type ", room_type)
		candidates.erase(pos)
		candidates = candidates.filter(func(n): !LevelManager.rooms.has(n))
		if candidates.size() == 0 and rooms_to_place > 0:
			candidates = find_new_candidates()
			print("Refreshed candidates: ", candidates)
	
	ensure_special_rooms(start_pos)
	update_dead_ends()
	place_special_rooms()
	print("Final rooms: ", LevelManager.rooms.keys())
	print("Room types: ", LevelManager.rooms.values().map(func(r): return r.type))
	validate_start_neighbors(start_pos)

func add_room(pos: Vector2i, type: String):
	LevelManager.rooms[pos] = {"type": type}
	print("Added room data at ", pos, " with type ", type)

func can_place_room(pos: Vector2i) -> bool:
	if pos.x < -8 or pos.x >= 8 or pos.y < -8 or pos.y >= 8:
		return false
	if LevelManager.rooms.has(pos):
		return false
	var neighbor_count = 0
	for n in get_neighbors(pos):
		if LevelManager.rooms.has(n):
			neighbor_count += 1
			if get_neighbor_count(n) >= 3:
				return false
	return neighbor_count > 0 and neighbor_count <= 2

func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(0, -1), # North
		pos + Vector2i(0, 1),  # South
		pos + Vector2i(1, 0),  # East
		pos + Vector2i(-1, 0)  # West
	]

func get_neighbor_count(pos: Vector2i) -> int:
	var count = 0
	for n in get_neighbors(pos):
		if LevelManager.rooms.has(n):
			count += 1
	return count

func is_neighbor_of_start(pos: Vector2i, start_pos: Vector2i) -> bool:
	return pos in get_neighbors(start_pos)

func find_new_candidates() -> Array[Vector2i]:
	var new_candidates: Array[Vector2i] = []
	for pos in LevelManager.rooms:
		for n in get_neighbors(pos):
			if !LevelManager.rooms.has(n) and can_place_room(n):
				new_candidates.append(n)
	return new_candidates

func ensure_special_rooms(start_pos: Vector2i):
	var required_dead_ends = 3
	var placed = 0
	var branch_points = LevelManager.rooms.keys().filter(func(pos): get_neighbor_count(pos) <= 2 and pos != start_pos)
	if branch_points.size() == 0:
		branch_points = LevelManager.rooms.keys().filter(func(pos): pos != start_pos)
	
	while placed < required_dead_ends and branch_points.size() > 0:
		var branch_pos = branch_points[randi() % branch_points.size()]
		var candidates = get_neighbors(branch_pos).filter(func(n): !LevelManager.rooms.has(n) and n.x >= -8 and n.x < 8 and n.y >= -8 and n.y < 8)
		if candidates.size() > 0:
			var pos = candidates[randi() % candidates.size()]
			add_room(pos, "normal")
			placed += 1
			print("Created dead-end at ", pos, " from ", branch_pos)
		branch_points.erase(branch_pos)
	
	if placed < required_dead_ends:
		for i in range(required_dead_ends - placed):
			var pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
			while LevelManager.rooms.has(pos) or !can_place_room(pos):
				pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
			add_room(pos, "normal")
			print("Forced dead-end at ", pos)

func update_dead_ends():
	LevelManager.dead_ends.clear()
	for pos in LevelManager.rooms:
		if get_neighbor_count(pos) == 1 and LevelManager.rooms[pos].type == "normal":
			LevelManager.dead_ends.append(pos)
	print("Dead ends: ", LevelManager.dead_ends)

func place_special_rooms():
	var start_pos = Vector2i(0, 0)
	var normal_rooms = LevelManager.rooms.keys().filter(func(pos): LevelManager.rooms[pos].type == "normal" and pos != start_pos)
	print("DEBUG: Normal rooms available: ", normal_rooms)
	
	# Place boss room
	if LevelManager.dead_ends.size() > 0:
		var boss_pos = LevelManager.dead_ends[0]
		var max_dist = (boss_pos - start_pos).length_squared()
		for pos in LevelManager.dead_ends:
			var dist = (pos - start_pos).length_squared()
			if dist > max_dist and (pos - start_pos).length_squared() > 4:
				boss_pos = pos
				max_dist = dist
		LevelManager.rooms[boss_pos].type = "boss"
		LevelManager.dead_ends.erase(boss_pos)
		print("Boss room at ", boss_pos, " distance: ", sqrt(max_dist))
	else:
		# Force a boss room if no dead-ends
		var pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
		while LevelManager.rooms.has(pos) or !can_place_room(pos) or (pos - start_pos).length_squared() <= 4:
			pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
		add_room(pos, "boss")
		print("Forced boss room at ", pos)
	
	# Guarantee a treasure room
	if LevelManager.dead_ends.size() > 0:
		var treasure_pos = LevelManager.dead_ends[randi() % LevelManager.dead_ends.size()]
		LevelManager.rooms[treasure_pos].type = "treasure"
		LevelManager.dead_ends.erase(treasure_pos)
		print("Treasure room at ", treasure_pos, " (dead-end)")
	else:
		# Force a treasure room if no dead-ends
		var pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
		while LevelManager.rooms.has(pos) or !can_place_room(pos):
			pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
		add_room(pos, "treasure")
		print("Forced treasure room at ", pos)
	
	# Guarantee a shop room
	if LevelManager.dead_ends.size() > 0:
		var shop_pos = LevelManager.dead_ends[randi() % LevelManager.dead_ends.size()]
		LevelManager.rooms[shop_pos].type = "shop"
		LevelManager.dead_ends.erase(shop_pos)
		print("Shop room at ", shop_pos, " (dead-end)")
	else:
		# Force a shop room if no dead-ends
		var pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
		while LevelManager.rooms.has(pos) or !can_place_room(pos):
			pos = Vector2i(randi_range(-8, 7), randi_range(-8, 7))
		add_room(pos, "shop")
		print("Forced shop room at ", pos)

func validate_start_neighbors(start_pos: Vector2i):
	var neighbor_count = get_neighbor_count(start_pos)
	var special_count = 0
	for n in get_neighbors(start_pos):
		if LevelManager.rooms.has(n) and LevelManager.rooms[n].type in ["shop", "treasure"]:
			special_count += 1
	print("DEBUG: Start room has ", neighbor_count, " neighbors, ", special_count, " specials")
	if neighbor_count < 2 or neighbor_count > 3:
		print("ERROR: Start room has invalid neighbor count: ", neighbor_count)
	if special_count > 1:
		print("ERROR: Start room has too many specials: ", special_count)
	if LevelManager.rooms.has(start_pos + Vector2i(1, 0)) and LevelManager.rooms[start_pos + Vector2i(1, 0)].type == "boss":
		print("ERROR: Boss room adjacent to start")
