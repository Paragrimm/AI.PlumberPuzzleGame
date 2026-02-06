class_name PuzzleGenerator
## Generiert spielbare Puzzles algorithmisch.


## Konfiguration für den Generator.
class GeneratorConfig:
	var grid_width: int = 4
	var grid_height: int = 4
	var start_position: Vector2i = Vector2i(-1, -1)  # -1 = zufällig
	var end_position: Vector2i = Vector2i(-1, -1)  # -1 = zufällig
	var min_path_length: int = 4
	var max_generation_attempts: int = 100
	var min_start_end_distance: int = 3  # Mindestabstand zwischen Start und Ende


## Generiert ein neues Puzzle.
static func generate(config: GeneratorConfig = null) -> PuzzleDefinition:
	if config == null:
		config = GeneratorConfig.new()

	for attempt in range(config.max_generation_attempts):
		var puzzle := _try_generate(config)
		if puzzle != null and PuzzleValidator.is_valid(puzzle):
			return puzzle

	push_error("Failed to generate valid puzzle after %d attempts" % config.max_generation_attempts)
	return null


static func _try_generate(config: GeneratorConfig) -> PuzzleDefinition:
	var grid := GridDefinition.new(config.grid_width, config.grid_height)

	# 1. Start- und Endposition bestimmen (mit Mindestabstand)
	var start_pos := _determine_start_position(config, grid)
	var end_pos := _determine_end_position(config, grid, start_pos)

	# Prüfen ob Mindestabstand eingehalten wird
	var distance := GridLogic.manhattan_distance(start_pos, end_pos)
	if distance < config.min_start_end_distance:
		return null  # Neuer Versuch

	# 2. Gültigen Pfad generieren (Random Walk)
	var path := _generate_path(grid, start_pos, end_pos, config.min_path_length)
	if path.size() == 0:
		return null

	# 3. Tiles entlang des Pfades platzieren
	_place_path_tiles(grid, path)

	# 4. Restliche Zellen mit zufälligen Tiles füllen
	_fill_remaining_tiles(grid)

	# 5. Puzzle erstellen und gelösten Zustand speichern
	var puzzle := PuzzleDefinition.new(grid)
	puzzle.id = _generate_id()
	puzzle.store_solved_state()

	# 6. Tiles zufällig rotieren (außer Start/Ende)
	_randomize_rotations(puzzle.grid)

	return puzzle


static func _determine_start_position(config: GeneratorConfig, grid: GridDefinition) -> Vector2i:
	if config.start_position != Vector2i(-1, -1):
		return config.start_position

	# Zufällige Position am Rand
	return _get_random_edge_position(grid)


static func _determine_end_position(
	config: GeneratorConfig, grid: GridDefinition, start_pos: Vector2i
) -> Vector2i:
	if config.end_position != Vector2i(-1, -1):
		return config.end_position

	# Versuche eine Position mit ausreichend Abstand zu finden
	var best_pos := Vector2i(-1, -1)
	var best_distance := 0

	for attempt in range(50):
		var end_pos := _get_random_edge_position(grid)

		# Überspringen wenn gleiche Position
		if end_pos == start_pos:
			continue

		var distance := GridLogic.manhattan_distance(start_pos, end_pos)

		# Wenn Mindestabstand erreicht, sofort nehmen
		if distance >= config.min_start_end_distance:
			return end_pos

		# Ansonsten beste Position merken
		if distance > best_distance:
			best_distance = distance
			best_pos = end_pos

	# Fallback: beste gefundene Position
	if best_pos != Vector2i(-1, -1):
		return best_pos

	# Notfall-Fallback: gegenüberliegende Ecke
	return Vector2i(grid.width - 1 - start_pos.x, grid.height - 1 - start_pos.y)


static func _get_random_edge_position(grid: GridDefinition) -> Vector2i:
	var edge := randi() % 4

	match edge:
		0:  # TOP
			return Vector2i(randi() % grid.width, 0)
		1:  # RIGHT
			return Vector2i(grid.width - 1, randi() % grid.height)
		2:  # BOTTOM
			return Vector2i(randi() % grid.width, grid.height - 1)
		3:  # LEFT
			return Vector2i(0, randi() % grid.height)

	return Vector2i.ZERO


static func _generate_path(
	grid: GridDefinition, start: Vector2i, end: Vector2i, min_length: int
) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	var current := start

	while current != end:
		var neighbors := grid.get_neighbor_positions(current)
		var unvisited: Array[Vector2i] = []

		for neighbor in neighbors:
			if neighbor not in visited:
				unvisited.append(neighbor)

		# Ende bevorzugen wenn erreichbar und Pfad lang genug
		if end in unvisited and path.size() >= min_length:
			path.append(end)
			break

		if unvisited.size() == 0:
			# Sackgasse - von vorne anfangen
			return []

		# Zufälligen unbesuchten Nachbarn wählen
		var next: Vector2i = unvisited[randi() % unvisited.size()]
		visited[next] = true
		path.append(next)
		current = next

		# Abbruch bei zu langem Pfad
		if path.size() > grid.width * grid.height:
			return []

	return path


static func _place_path_tiles(grid: GridDefinition, path: Array[Vector2i]) -> void:
	for i in range(path.size()):
		var pos := path[i]
		var tile_type: TileType.Type
		var rotation: int

		if i == 0:
			# START-Tile
			tile_type = TileType.Type.START
			var next_pos := path[i + 1]
			var direction := GridLogic.get_direction_between(pos, next_pos)
			rotation = direction
		elif i == path.size() - 1:
			# END-Tile
			tile_type = TileType.Type.END
			var prev_pos := path[i - 1]
			var direction := GridLogic.get_direction_between(pos, prev_pos)
			rotation = direction
		else:
			# Mittleres Tile
			var prev_pos := path[i - 1]
			var next_pos := path[i + 1]
			var dir_from_prev := GridLogic.get_direction_between(pos, prev_pos)
			var dir_to_next := GridLogic.get_direction_between(pos, next_pos)

			# Bestimmen ob STRAIGHT oder CORNER
			var result := _determine_tile_type_and_rotation(dir_from_prev, dir_to_next)
			tile_type = result[0]
			rotation = result[1]

		var tile := TileDefinition.new(tile_type, rotation)
		grid.set_tile_at(pos, tile)


static func _determine_tile_type_and_rotation(dir_a: int, dir_b: int) -> Array:
	# Prüfen ob die Richtungen gegenüberliegend sind (STRAIGHT)
	if TileConnection.get_opposite_side(dir_a) == dir_b:
		# STRAIGHT - Rotation basierend auf Achse
		if dir_a == TileConnection.Side.TOP or dir_a == TileConnection.Side.BOTTOM:
			return [TileType.Type.STRAIGHT, 0]  # Vertikal
		else:
			return [TileType.Type.STRAIGHT, 90]  # Horizontal

	# CORNER - Rotation ermitteln
	var sides := [dir_a, dir_b]
	sides.sort()

	# Base-Verbindung von CORNER bei 0° ist TOP und RIGHT
	var rotation := _find_corner_rotation(sides)
	return [TileType.Type.CORNER, rotation]


static func _find_corner_rotation(target_sides: Array) -> int:
	# CORNER bei 0°: TOP (0) + RIGHT (90)
	# CORNER bei 90°: RIGHT (90) + BOTTOM (180)
	# CORNER bei 180°: BOTTOM (180) + LEFT (270)
	# CORNER bei 270°: LEFT (270) + TOP (0)

	var corner_configs := [
		[[TileConnection.Side.TOP, TileConnection.Side.RIGHT], 0],
		[[TileConnection.Side.RIGHT, TileConnection.Side.BOTTOM], 90],
		[[TileConnection.Side.BOTTOM, TileConnection.Side.LEFT], 180],
		[[TileConnection.Side.LEFT, TileConnection.Side.TOP], 270],
	]

	for config in corner_configs:
		var sides: Array = config[0].duplicate()
		sides.sort()
		if sides[0] == target_sides[0] and sides[1] == target_sides[1]:
			return config[1]

	return 0


static func _fill_remaining_tiles(grid: GridDefinition) -> void:
	for i in range(grid.get_tile_count()):
		var pos := grid.index_to_position(i)
		var tile := grid.get_tile_at(pos)

		if tile != null:
			continue  # Bereits belegt

		# Zufälliges Tile (STRAIGHT oder CORNER)
		var tile_type: TileType.Type
		if randf() < 0.5:
			tile_type = TileType.Type.STRAIGHT
		else:
			tile_type = TileType.Type.CORNER

		var valid_rotations := TileType.get_valid_rotations(tile_type)
		var rotation: int = valid_rotations[randi() % valid_rotations.size()]

		var new_tile := TileDefinition.new(tile_type, rotation)
		grid.set_tile_at(pos, new_tile)


static func _randomize_rotations(grid: GridDefinition) -> void:
	for i in range(grid.get_tile_count()):
		var pos := grid.index_to_position(i)
		var tile := grid.get_tile_at(pos)

		if tile == null:
			continue

		if not TileType.is_rotatable(tile.type):
			continue

		# Zufällige Anzahl Rotationen
		var rotations := randi() % 4
		for j in range(rotations):
			tile.rotate_clockwise()


static func _generate_id() -> String:
	return "puzzle_%d" % Time.get_unix_time_from_system()
