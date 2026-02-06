extends Node2D

class_name PumberGame

var grid: Dictionary = {}  # grid_pos -> PipeTile data
var grid_size: Vector2i = Vector2i(2, 3)
var tile_size: int = 90
var selected_tile_pos: Vector2i = Vector2i(-1, -1)
var start_pos: Vector2i = Vector2i.ZERO
var end_pos: Vector2i = Vector2i.ZERO
var is_solved: bool = false


func _ready():
	print("Game _ready called")
	_create_puzzle()
	print("Puzzle created with ", grid.size(), " tiles")


func _create_puzzle():
	"""Create a simple puzzle layout"""
	start_pos = Vector2i(0, 0)
	end_pos = Vector2i(0, grid_size.y - 1)

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			grid[pos] = {"type": 0, "rotation": 0}

	# Place start and end
	grid[start_pos]["type"] = 4  # START
	grid[end_pos]["type"] = 5  # END

	# Place puzzle pieces
	var puzzle_positions = []
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			if pos != start_pos and pos != end_pos:
				puzzle_positions.append(pos)

	puzzle_positions.shuffle()
	var pipe_types = [0, 1]  # STRAIGHT, CORNER

	for i in range(puzzle_positions.size()):
		var pos = puzzle_positions[i]
		grid[pos]["type"] = pipe_types[i % pipe_types.size()]
		grid[pos]["rotation"] = (randi() % 4) * 90


func _draw():
	# Draw all tiles
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			_draw_tile(pos)


func _draw_tile(grid_pos: Vector2i):
	var world_pos = Vector2(grid_pos) * tile_size
	var tile_data = grid.get(grid_pos)
	if not tile_data:
		return

	# Draw background
	draw_rect(Rect2(world_pos, Vector2(tile_size, tile_size)), Color(0.2, 0.2, 0.2))

	var pipe_type = tile_data["type"]
	var rotation = tile_data["rotation"]

	match pipe_type:
		4:  # START
			_draw_start_at(world_pos)
		5:  # END
			_draw_end_at(world_pos)
		0:  # STRAIGHT
			_draw_straight_at(world_pos, rotation)
		1:  # CORNER
			_draw_corner_at(world_pos, rotation)


func _draw_start_at(world_pos: Vector2):
	var center = world_pos + Vector2(tile_size / 2, tile_size / 2)
	draw_circle(center, 20, Color.GREEN)
	draw_circle(center, 14, Color.LIGHT_GREEN)


func _draw_end_at(world_pos: Vector2):
	var center = world_pos + Vector2(tile_size / 2, tile_size / 2)
	draw_circle(center, 20, Color.RED)
	draw_circle(center, 14, Color.LIGHT_CORAL)


func _draw_straight_at(world_pos: Vector2, rotation: int):
	var center = world_pos + Vector2(tile_size / 2, tile_size / 2)
	if rotation == 0 or rotation == 180:
		draw_line(
			Vector2(center.x, world_pos.y),
			Vector2(center.x, world_pos.y + tile_size),
			Color.BLUE,
			16
		)
	else:
		draw_line(
			Vector2(world_pos.x, center.y),
			Vector2(world_pos.x + tile_size, center.y),
			Color.BLUE,
			16
		)


func _draw_corner_at(world_pos: Vector2, rotation: int):
	var center = world_pos + Vector2(tile_size / 2, tile_size / 2)
	var dirs = []

	match rotation:
		0:
			dirs = [Vector2.UP, Vector2.RIGHT]
		90:
			dirs = [Vector2.RIGHT, Vector2.DOWN]
		180:
			dirs = [Vector2.DOWN, Vector2.LEFT]
		270:
			dirs = [Vector2.LEFT, Vector2.UP]

	for dir in dirs:
		var end_pos = center + dir * (tile_size / 2)
		draw_line(center, end_pos, Color.BLUE, 16)


func _input(event: InputEvent):
	"""Handle input"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var tile_pos = _get_tile_at_mouse()
			if tile_pos != Vector2i(-1, -1):
				_rotate_tile(tile_pos)
				_check_puzzle()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var tile_pos = _get_tile_at_mouse()
			if tile_pos != Vector2i(-1, -1):
				selected_tile_pos = tile_pos
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_N:
			_create_puzzle()
			queue_redraw()


func _get_tile_at_mouse() -> Vector2i:
	var mouse_pos = get_local_mouse_position()
	var tile_x = int(mouse_pos.x / tile_size)
	var tile_y = int(mouse_pos.y / tile_size)
	var pos = Vector2i(tile_x, tile_y)

	if pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y:
		return pos
	return Vector2i(-1, -1)


func _rotate_tile(pos: Vector2i):
	var tile_data = grid.get(pos)
	if tile_data and tile_data["type"] != 4 and tile_data["type"] != 5:
		tile_data["rotation"] = (tile_data["rotation"] + 90) % 360
		queue_redraw()


func _check_puzzle():
	if is_path_connected(start_pos, end_pos):
		_on_puzzle_solved()


func is_path_connected(from: Vector2i, to: Vector2i) -> bool:
	var visited = {}
	var queue = [from]
	visited[from] = true

	while queue.size() > 0:
		var current_pos = queue.pop_front()

		if current_pos == to:
			return true

		var connections = _get_tile_connections(current_pos)

		for direction in connections:
			var next_pos = current_pos + direction

			if (
				next_pos.x < 0
				or next_pos.x >= grid_size.x
				or next_pos.y < 0
				or next_pos.y >= grid_size.y
			):
				continue

			if visited.get(next_pos, false):
				continue

			var next_connections = _get_tile_connections(next_pos)
			var opposite_direction = -direction

			if opposite_direction in next_connections:
				visited[next_pos] = true
				queue.append(next_pos)

	return false


func _get_tile_connections(pos: Vector2i) -> Array:
	var tile_data = grid.get(pos)
	if not tile_data:
		return []

	var pipe_type = tile_data["type"]
	var rotation = tile_data["rotation"]

	match pipe_type:
		4:  # START
			return [Vector2.DOWN]
		5:  # END
			return [Vector2.UP]
		0:  # STRAIGHT
			if rotation == 0 or rotation == 180:
				return [Vector2.UP, Vector2.DOWN]
			else:
				return [Vector2.LEFT, Vector2.RIGHT]
		1:  # CORNER
			match rotation:
				0:
					return [Vector2.UP, Vector2.RIGHT]
				90:
					return [Vector2.RIGHT, Vector2.DOWN]
				180:
					return [Vector2.DOWN, Vector2.LEFT]
				270:
					return [Vector2.LEFT, Vector2.UP]
	return []


func _on_puzzle_solved():
	is_solved = true
	print("Puzzle solved!")

	var solved_label = get_node("UI/SolvedLabel")
	var tween = create_tween()
	tween.tween_property(solved_label, "modulate", Color(1, 1, 0, 1), 0.5)
	tween.tween_callback(func(): await get_tree().create_timer(2.0).timeout)
	tween.tween_property(solved_label, "modulate", Color(1, 1, 0, 0), 0.5)
