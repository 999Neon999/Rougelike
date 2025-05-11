extends CanvasLayer

var visited_rooms: Array[Vector2i] = []

func _ready():
	print("GUI _ready called, layer: ", layer)
	visible = true
	visited_rooms.append(Vector2i(0, 0))
	draw_minimap()

func draw_minimap():
	var minimap = $Minimap
	if not minimap:
		print("Error: Minimap node not found")
		return
	minimap.visible = true
	# Dynamically position based on viewport size
	var viewport_size = get_viewport().size
	minimap.position = Vector2(viewport_size.x - 180, 10)  # 160 + 20 padding
	minimap.size = Vector2(160, 160)
	print("Minimap position: ", minimap.position, " size: ", minimap.size, " viewport: ", viewport_size)
	
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
	# Center the grid around (0, 0) by mapping -8 to 7 to grid positions
	for y in range(-8, 8):
		for x in range(-8, 8):
			var pos = Vector2i(x, y)
			var cell = ColorRect.new()
			cell.size = Vector2(10, 10)
			if LevelManager.rooms.has(pos):
				if pos in visited_rooms:
					match LevelManager.rooms[pos].type:
						"start": cell.color = Color(0, 1, 0, 1)
						"normal": cell.color = Color(1, 1, 1, 1)
						"boss": cell.color = Color(1, 0, 0, 1)
						"treasure": cell.color = Color(1, 1, 0, 1)
						"shop": cell.color = Color(0, 0, 1, 1)
					print("Drawing cell at ", pos, " color: ", cell.color)
				else:
					cell.color = Color(0, 0, 0, 0.5)  # Dim for unvisited rooms
			else:
				cell.color = Color(0, 0, 0, 0)
			map_grid.add_child(cell)
	print("Minimap drawn with ", map_grid.get_child_count(), " cells")
	print("Minimap rooms shown: ", LevelManager.rooms.keys())

func update_minimap(room_pos: Vector2i):
	if not room_pos in visited_rooms:
		visited_rooms.append(room_pos)
		draw_minimap()
