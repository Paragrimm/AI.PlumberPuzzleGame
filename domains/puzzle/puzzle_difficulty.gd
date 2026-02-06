class_name PuzzleDifficulty
## Berechnet den Schwierigkeitsgrad eines Puzzles dynamisch.

## Gewichtung der Faktoren.
const WEIGHT_GRID_SIZE := 0.3
const WEIGHT_ROTATIONS := 0.5
const WEIGHT_PATH_COMPLEXITY := 0.2


## Berechnet den Schwierigkeitsgrad eines Puzzles.
static func calculate(puzzle: PuzzleDefinition) -> float:
	if puzzle == null or puzzle.grid == null:
		return 0.0

	var grid_size_factor := _calculate_grid_size_factor(puzzle.grid)
	var rotation_factor := _calculate_rotation_factor(puzzle)
	var path_complexity_factor := _calculate_path_complexity_factor(puzzle)

	var difficulty := (
		grid_size_factor * WEIGHT_GRID_SIZE
		+ rotation_factor * WEIGHT_ROTATIONS
		+ path_complexity_factor * WEIGHT_PATH_COMPLEXITY
	)

	return difficulty


## Berechnet den Faktor basierend auf der Grid-Größe.
static func _calculate_grid_size_factor(grid: GridDefinition) -> float:
	var total_tiles := grid.width * grid.height
	# Normalisieren: 9 (3x3) = 1.0, 16 (4x4) = 1.78, 25 (5x5) = 2.78
	return float(total_tiles) / 9.0


## Berechnet den Faktor basierend auf drehbaren Tiles.
static func _calculate_rotation_factor(puzzle: PuzzleDefinition) -> float:
	var rotatable_count := 0
	var corner_count := 0

	for i in range(puzzle.grid.get_tile_count()):
		var tile := puzzle.grid.tiles[i]
		if tile == null:
			continue

		if TileType.is_rotatable(tile.type):
			rotatable_count += 1

			# Ecken haben mehr Rotationsmöglichkeiten = schwerer
			if tile.type == TileType.Type.CORNER:
				corner_count += 1

	# Mehr drehbare Tiles und Ecken = schwerer
	return float(rotatable_count) * 0.5 + float(corner_count) * 0.3


## Berechnet die Pfad-Komplexität (Anzahl Richtungswechsel).
static func _calculate_path_complexity_factor(puzzle: PuzzleDefinition) -> float:
	var path := PuzzleSolver.get_solution_path(puzzle)

	if path.size() < 3:
		return 0.0

	var direction_changes := 0
	var prev_direction: int = GridLogic.get_direction_between(path[0], path[1])

	for i in range(2, path.size()):
		var current_direction := GridLogic.get_direction_between(path[i - 1], path[i])
		if current_direction != prev_direction:
			direction_changes += 1
			prev_direction = current_direction

	# Mehr Richtungswechsel = mehr Ecken = schwerer
	return float(direction_changes) * 0.5


## Gibt einen lesbaren Schwierigkeitsgrad zurück.
static func get_difficulty_label(difficulty: float) -> String:
	if difficulty < 1.5:
		return "Leicht"
	elif difficulty < 2.5:
		return "Mittel"
	elif difficulty < 3.5:
		return "Schwer"
	else:
		return "Experte"
