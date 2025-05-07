extends CanvasLayer

func _ready():
	draw_minimap()

func draw_minimap():
	var minimap = $Minimap
	if not minimap:
		print("Error: Minimap node not found")
		return
	var map_grid = $Minimap/MapGrid
	if not map_grid:
		print("Error: MapGrid node not found under Minimap")
		return
	map_grid.columns = 16
	for y in range(-8, 8):
		for x in range(-8, 8):
			var pos = Vector2i(x, y)
			var cell = ColorRect.new()
			cell.size = Vector2(10, 10)
			if LevelManager.rooms.has(pos):
				match LevelManager.rooms[pos].type:
					"start": cell.color = Color(0, 1, 0)  # Green
					"normal": cell.color = Color(1, 1, 1)  # White
					"boss": cell.color = Color(1, 0, 0)    # Red
					"treasure": cell.color = Color(1, 1, 0) # Yellow
					"shop": cell.color = Color(0, 0, 1)    # Blue
			else:
				cell.color = Color(0, 0, 0, 0)  # Transparent
			map_grid.add_child(cell)
	print("Minimap drawn with ", map_grid.get_child_count(), " cells")
	print("Minimap rooms shown: ", LevelManager.rooms.keys())
