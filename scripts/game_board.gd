class_name GameBoard
extends GridContainer

## Manages the puzzle grid and checks for path completion

signal puzzle_solved
signal path_updated(connected_count: int, total_count: int)

const PipeTileScene := preload("res://scenes/pipe_tile.tscn")

@export var grid_width: int = 5
@export var grid_height: int = 5
@export var tile_size: int = 64

var tiles: Array[Array] = []  # 2D array of PipeTile
var start_pos: Vector2i = Vector2i.ZERO
var goal_pos: Vector2i = Vector2i.ZERO

## Direction offsets: UP, RIGHT, DOWN, LEFT
const DIR_OFFSETS := [
	Vector2i(0, -1),  # UP
	Vector2i(1, 0),  # RIGHT
	Vector2i(0, 1),  # DOWN
	Vector2i(-1, 0),  # LEFT
]

## Opposite direction mapping
const OPPOSITE_DIR := [2, 3, 0, 1]  # UP->DOWN, RIGHT->LEFT, etc.


func _ready() -> void:
	columns = grid_width


func generate_puzzle(width: int = 5, height: int = 5, difficulty: int = 1) -> void:
	grid_width = width
	grid_height = height
	columns = grid_width

	_clear_board()
	_create_tiles()
	_generate_solvable_puzzle(difficulty)
	_scramble_tiles()
	check_path()


func _clear_board() -> void:
	for child in get_children():
		child.queue_free()
	tiles.clear()


func _create_tiles() -> void:
	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			var tile: PipeTile = PipeTileScene.instantiate()
			tile.custom_minimum_size = Vector2(tile_size, tile_size)
			tile.grid_position = Vector2i(x, y)
			tile.tile_rotated.connect(_on_tile_rotated)
			add_child(tile)
			row.append(tile)
		tiles.append(row)


func _generate_solvable_puzzle(difficulty: int) -> void:
	## Generate a puzzle that has a valid solution
	## Uses path carving algorithm

	# Set start and goal positions
	start_pos = Vector2i(0, grid_height / 2)
	goal_pos = Vector2i(grid_width - 1, grid_height / 2)

	# Generate a random path from start to goal
	var path := _generate_random_path(start_pos, goal_pos)

	# Mark tiles along the path with appropriate pipe types
	_set_path_tiles(path)

	# Fill remaining tiles with random pipes
	_fill_remaining_tiles()

	# Set start and goal tiles
	var start_tile := get_tile(start_pos)
	start_tile.setup(PipeTile.PipeType.START, start_pos, true)
	start_tile.rotation_steps = _get_start_rotation(path)
	start_tile._update_texture()

	var goal_tile := get_tile(goal_pos)
	goal_tile.setup(PipeTile.PipeType.GOAL, goal_pos, true)
	goal_tile.rotation_steps = _get_goal_rotation(path)
	goal_tile._update_texture()


func _generate_random_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	## Generate a random path using modified random walk
	var path: Array[Vector2i] = [from]
	var current := from
	var visited := {from: true}
	var max_attempts := 1000
	var attempts := 0

	while current != to and attempts < max_attempts:
		attempts += 1
		var possible_moves: Array[Vector2i] = []

		# Prefer moving towards goal
		var dir_to_goal := to - current
		var preferred_dirs: Array[int] = []

		if dir_to_goal.x > 0:
			preferred_dirs.append(1)  # RIGHT
		elif dir_to_goal.x < 0:
			preferred_dirs.append(3)  # LEFT
		if dir_to_goal.y > 0:
			preferred_dirs.append(2)  # DOWN
		elif dir_to_goal.y < 0:
			preferred_dirs.append(0)  # UP

		# Try preferred directions first with some randomness
		var all_dirs := [0, 1, 2, 3]
		all_dirs.shuffle()

		# Weight towards goal direction
		if randf() < 0.7 and preferred_dirs.size() > 0:
			all_dirs = preferred_dirs + all_dirs

		for dir in all_dirs:
			var next_pos: Vector2i = current + DIR_OFFSETS[dir]
			if _is_valid_pos(next_pos) and not visited.has(next_pos):
				possible_moves.append(next_pos)
				break

		if possible_moves.is_empty():
			# Backtrack if stuck
			if path.size() > 1:
				path.pop_back()
				current = path[-1]
			continue

		current = possible_moves[0]
		path.append(current)
		visited[current] = true

	return path


func _set_path_tiles(path: Array[Vector2i]) -> void:
	for i in range(path.size()):
		var pos := path[i]
		var tile := get_tile(pos)

		if i == 0 or i == path.size() - 1:
			continue  # Skip start and goal

		# Determine connections based on neighbors in path
		var connections := [false, false, false, false]

		if i > 0:
			var prev := path[i - 1]
			var dir := _get_direction(pos, prev)
			if dir >= 0:
				connections[dir] = true

		if i < path.size() - 1:
			var next := path[i + 1]
			var dir := _get_direction(pos, next)
			if dir >= 0:
				connections[dir] = true

		# Find matching pipe type and rotation
		var pipe_type := _find_matching_pipe_type(connections)
		tile.setup(pipe_type.type, pos, false)
		tile.rotation_steps = pipe_type.rotation
		tile._update_texture()


func _get_direction(from: Vector2i, to: Vector2i) -> int:
	var diff := to - from
	for i in range(4):
		if DIR_OFFSETS[i] == diff:
			return i
	return -1


func _find_matching_pipe_type(connections: Array) -> Dictionary:
	## Find a pipe type and rotation that matches the required connections
	for type in [
		PipeTile.PipeType.STRAIGHT,
		PipeTile.PipeType.CORNER,
		PipeTile.PipeType.T_PIPE,
		PipeTile.PipeType.CROSS
	]:
		for rot in range(4):
			var test_connections := _get_rotated_connections(type, rot)
			if _connections_match(test_connections, connections):
				return {"type": type, "rotation": rot}

	# Default to corner if no match
	return {"type": PipeTile.PipeType.CORNER, "rotation": 0}


func _get_rotated_connections(type: PipeTile.PipeType, rotation: int) -> Array[bool]:
	var base: Array = PipeTile.PIPE_CONNECTIONS[type]
	var rotated: Array[bool] = [false, false, false, false]
	for i in range(4):
		# Match PipeTile.get_connections() logic - Godot rotates CCW for positive angles
		var source_index := (i + rotation) % 4
		rotated[i] = base[source_index]
	return rotated


func _connections_match(a: Array, b: Array) -> bool:
	## Check if pipe a has at least the connections required by b
	for i in range(4):
		if b[i] and not a[i]:
			return false
	return true


func _fill_remaining_tiles() -> void:
	var pipe_types := [
		PipeTile.PipeType.STRAIGHT,
		PipeTile.PipeType.CORNER,
		PipeTile.PipeType.T_PIPE,
		PipeTile.PipeType.STRAIGHT,
		PipeTile.PipeType.CORNER,
	]

	for y in range(grid_height):
		for x in range(grid_width):
			var tile := tiles[y][x] as PipeTile
			if tile.pipe_type == PipeTile.PipeType.STRAIGHT and not tile.is_locked:
				# Check if this tile was set by the path
				if (
					tile.rotation_steps == 0
					and Vector2i(x, y) != start_pos
					and Vector2i(x, y) != goal_pos
				):
					var random_type: PipeTile.PipeType = pipe_types[randi() % pipe_types.size()]
					tile.setup(random_type, Vector2i(x, y), false)


func _get_start_rotation(path: Array[Vector2i]) -> int:
	if path.size() < 2:
		return 0
	var dir := _get_direction(path[0], path[1])
	# START connects DOWN (index 2) at rotation 0
	# With CCW rotation: rotated[i] = base[(i + rotation) % 4]
	# We want rotated[dir] = true, and base[2] = true
	# So: (dir + rotation) % 4 = 2 → rotation = (2 - dir + 4) % 4
	return (2 - dir + 4) % 4


func _get_goal_rotation(path: Array[Vector2i]) -> int:
	if path.size() < 2:
		return 0
	var dir := _get_direction(path[-1], path[-2])
	# GOAL connects UP (index 0) at rotation 0
	# With CCW rotation: rotated[i] = base[(i + rotation) % 4]
	# We want rotated[dir] = true, and base[0] = true
	# So: (dir + rotation) % 4 = 0 → rotation = (0 - dir + 4) % 4 = (-dir + 4) % 4
	return (-dir + 4) % 4


func _scramble_tiles() -> void:
	## Randomly rotate non-locked tiles
	for y in range(grid_height):
		for x in range(grid_width):
			var tile := tiles[y][x] as PipeTile
			if not tile.is_locked:
				var random_rotations := randi() % 4
				for i in range(random_rotations):
					tile.rotation_steps = (tile.rotation_steps + 1) % 4
				tile._update_texture()


func _is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height


func get_tile(pos: Vector2i) -> PipeTile:
	if _is_valid_pos(pos):
		return tiles[pos.y][pos.x]
	return null


func check_path() -> bool:
	## Check if there's a valid path from start to goal
	## Uses flood fill / BFS

	# Reset all tile connection states
	for row in tiles:
		for tile in row:
			(tile as PipeTile).set_connected(false)

	var visited := {}
	var queue: Array[Vector2i] = [start_pos]
	visited[start_pos] = true
	var connected_tiles: Array[PipeTile] = []

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		var current_tile := get_tile(current)
		connected_tiles.append(current_tile)

		# Check all four directions
		for dir in range(4):
			if not current_tile.has_connection(dir):
				continue

			var neighbor_pos: Vector2i = current + DIR_OFFSETS[dir]
			if not _is_valid_pos(neighbor_pos):
				continue
			if visited.has(neighbor_pos):
				continue

			var neighbor_tile := get_tile(neighbor_pos)
			var opposite: int = OPPOSITE_DIR[dir]

			# Check if neighbor connects back to current
			if neighbor_tile.has_connection(opposite):
				visited[neighbor_pos] = true
				queue.append(neighbor_pos)

	# Mark connected tiles
	for tile in connected_tiles:
		tile.set_connected(true)

	# Count connected tiles for progress
	var total_tiles := grid_width * grid_height
	path_updated.emit(connected_tiles.size(), total_tiles)

	# Check if goal is reached
	if visited.has(goal_pos):
		puzzle_solved.emit()
		return true

	return false


func _on_tile_rotated(_tile: PipeTile) -> void:
	check_path()
