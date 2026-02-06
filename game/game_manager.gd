class_name GameManager
extends Node
## Verwaltet Spielzustand, Züge und Statistiken.

## Signal wenn ein Zug gemacht wurde.
signal move_made(move_count: int)

## Signal wenn sich die Anzahl Verbindungen geändert hat.
signal connections_changed(connection_count: int)

## Signal wenn das Puzzle gelöst wurde.
signal puzzle_solved

## Signal wenn das Puzzle zurückgesetzt wurde.
signal puzzle_reset

## Das aktuelle Puzzle.
var current_puzzle: PuzzleDefinition:
	set = set_current_puzzle

## Anzahl der Züge (Rotationen) im aktuellen Puzzle.
var move_count: int = 0

## Anzahl der aktuellen Verbindungen (vom Start aus erreichbar).
var connection_count: int = 0

## Ob das Puzzle bereits gelöst wurde.
var is_solved: bool = false


func set_current_puzzle(value: PuzzleDefinition) -> void:
	current_puzzle = value
	_reset_stats()
	_update_connection_count()


func _reset_stats() -> void:
	move_count = 0
	is_solved = false
	move_made.emit(move_count)


## Wird aufgerufen wenn ein Tile rotiert werden soll.
func rotate_tile_at(pos: Vector2i) -> void:
	if current_puzzle == null or is_solved:
		return

	var tile := current_puzzle.grid.get_tile_at(pos)
	if tile == null:
		return

	if not TileType.is_rotatable(tile.type):
		return

	# Tile rotieren
	tile.rotate_clockwise()

	# Zug zählen
	move_count += 1
	move_made.emit(move_count)

	# Verbindungen aktualisieren
	_update_connection_count()

	# Win-Condition prüfen
	_check_win_condition()


func _update_connection_count() -> void:
	if current_puzzle == null:
		connection_count = 0
		connections_changed.emit(0)
		return

	connection_count = PuzzleSolver.count_connected_tiles(current_puzzle)
	connections_changed.emit(connection_count)


func _check_win_condition() -> void:
	if current_puzzle == null:
		return

	if current_puzzle.is_solved():
		is_solved = true

		# Fortschritt speichern
		if ProgressTracker:
			ProgressTracker.mark_puzzle_solved(current_puzzle.id, move_count)

		puzzle_solved.emit()


## Setzt das aktuelle Puzzle zurück.
func reset_puzzle() -> void:
	if current_puzzle == null:
		return

	current_puzzle.reset()
	_reset_stats()
	_update_connection_count()
	puzzle_reset.emit()


## Lädt ein neues Puzzle vom Generator.
func load_new_puzzle(config: PuzzleGenerator.GeneratorConfig = null) -> void:
	var puzzle := PuzzleGenerator.generate(config)
	if puzzle != null:
		set_current_puzzle(puzzle)
