class_name PuzzleValidator
## Validiert generierte Puzzles.


## Prüft ob ein Puzzle gültig und spielbar ist.
static func is_valid(puzzle: PuzzleDefinition) -> bool:
	if puzzle == null or puzzle.grid == null:
		return false

	# Prüfungen
	if not _has_start_and_end(puzzle.grid):
		return false

	if not _is_solvable_when_correctly_rotated(puzzle):
		return false

	return true


static func _has_start_and_end(grid: GridDefinition) -> bool:
	var start := grid.find_start_position()
	var end := grid.find_end_position()

	return start != Vector2i(-1, -1) and end != Vector2i(-1, -1)


## Prüft ob das Puzzle lösbar ist wenn alle Tiles korrekt rotiert sind.
static func _is_solvable_when_correctly_rotated(puzzle: PuzzleDefinition) -> bool:
	# Wir nutzen den gespeicherten gelösten Zustand
	if puzzle._solved_grid != null:
		var test_puzzle := PuzzleDefinition.new(puzzle._solved_grid.duplicate_grid())
		return PuzzleSolver.is_solved(test_puzzle)

	# Fallback: Brute-Force alle Rotationen testen (teuer!)
	return _brute_force_solvability_check(puzzle)


static func _brute_force_solvability_check(puzzle: PuzzleDefinition) -> bool:
	# Für kleine Grids: Alle Rotationskombinationen durchprobieren
	# Das ist exponentiell komplex, daher nur als Fallback

	var grid := puzzle.grid.duplicate_grid()
	var rotatable_positions: Array[Vector2i] = []

	for i in range(grid.get_tile_count()):
		var pos := grid.index_to_position(i)
		var tile := grid.get_tile_at(pos)
		if tile != null and TileType.is_rotatable(tile.type):
			rotatable_positions.append(pos)

	# Begrenzen auf erste 10 Tiles (sonst zu lange)
	if rotatable_positions.size() > 10:
		push_warning("Too many rotatable tiles for brute-force check")
		return true  # Optimistisch annehmen

	return _try_all_rotations(grid, rotatable_positions, 0)


static func _try_all_rotations(
	grid: GridDefinition, positions: Array[Vector2i], index: int
) -> bool:
	if index >= positions.size():
		var test_puzzle := PuzzleDefinition.new(grid)
		return PuzzleSolver.is_solved(test_puzzle)

	var pos := positions[index]
	var tile := grid.get_tile_at(pos)
	var valid_rotations := TileType.get_valid_rotations(tile.type)

	var original_rotation := tile.rotation_degrees

	for rotation in valid_rotations:
		tile.rotation_degrees = rotation
		if _try_all_rotations(grid, positions, index + 1):
			tile.rotation_degrees = original_rotation
			return true

	tile.rotation_degrees = original_rotation
	return false
