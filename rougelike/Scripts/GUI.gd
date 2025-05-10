extends CanvasLayer

var visited_rooms: Array[Vector2i] = []  # Track visited rooms

func _ready():
	print("GUI _ready called, layer: ", layer)
	visible = true
	visited_rooms.append(Vector2i(0, 0))  # Start room is visited
	draw_minimap()

func draw_minimap():
	var minimap = $Minimap
	if not minimap:
		print("Error: Minimap node not found")
		return
	minimap.visible = true
	# Position in top-right (assuming 1280x720 viewport, adjust as needed)
	minimap.position = Vector2(1280 - 180, 10)  # 160 + 10 padding
	minimap.size = Vector2(160, 160)  # 16x16 grid, 10x10 cells
	print("Minimap position: ", minimap.position, " size: ", minimap.size)
	var map_grid = $Minimap/MapGrid
	if not map_grid:
		print("Error: MapGrid node not found under Minimap")
		return
	map_grid.visible = true
	map_grid.size = Vector2(160, 160)
	map_grid.columns = 16
	# Clear existing children
	for child in map_grid.get_children():
		child.queue_free()
	for y in range(-8, 8):
		for x in range(-8, 8):
			var pos = Vector2i(x, y)
			var cell = ColorRect.new()
			cell.size = Vector2(10, 10)  # Match tutorial size
			# Show rooms based on visited status (optional, can remove if you want all rooms visible)
			if LevelManager.rooms.has(pos) and pos in visited_rooms:
				match LevelManager.rooms[pos].type:
					"start": cell.color = Color(0, 1, 0, 1)
					"normal": cell.color = Color(1, 1, 1, 1)
					"boss": cell.color = Color(1, 0, 0, 1)
					"treasure": cell.color = Color(1, 1, 0, 1)
					"shop": cell.color = Color(0, 0, 1, 1)
			else:
				cell.color = Color(0, 0, 0, 0)  # Invisible if not visited
			map_grid.add_child(cell)
			print("Cell at ", pos, " color: ", cell.color, " size: ", cell.size)
	print("Minimap drawn with ", map_grid.get_child_count(), " cells")
	print("Minimap rooms shown: ", LevelManager.rooms.keys())

func update_minimap(room_pos: Vector2i):
	if not room_pos in visited_rooms:
		visited_rooms.append(room_pos)
		draw_minimap()  # Redraw to reveal the new room
