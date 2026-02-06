class_name PuzzleSolver
## Prüft ob ein Puzzle gelöst ist.


## Prüft ob das Puzzle gelöst ist (Start und Ende verbunden).
static func is_solved(puzzle: PuzzleDefinition) -> bool:
	if puzzle == null or puzzle.grid == null:
		return false

	return PathFinder.is_puzzle_solved(puzzle.grid)


## Findet den Lösungspfad (falls vorhanden).
static func get_solution_path(puzzle: PuzzleDefinition) -> Array[Vector2i]:
	if puzzle == null or puzzle.grid == null:
		return []

	var result := PathFinder.find_path(puzzle.grid)
	return result.path


## Zählt die Anzahl der verbundenen Tiles (vom Start aus erreichbar).
static func count_connected_tiles(puzzle: PuzzleDefinition) -> int:
	if puzzle == null or puzzle.grid == null:
		return 0

	var reachable := PathFinder.find_reachable_from_start(puzzle.grid)
	return reachable.size()
