class_name PuzzleDefinition
extends Resource
## Custom Resource als Wrapper um GridDefinition.
## Enthält Puzzle-Metadaten und Serialisierung.

## Eindeutige ID des Puzzles.
@export var id: String = ""

## Das Grid mit allen Tiles.
@export var grid: GridDefinition

## Die ursprüngliche (gelöste) Konfiguration zum Zurücksetzen.
## Wird beim Generieren gespeichert, BEVOR Tiles zufällig rotiert werden.
var _solved_grid: GridDefinition


func _init(puzzle_grid: GridDefinition = null) -> void:
	if puzzle_grid != null:
		grid = puzzle_grid


## Berechnet die Schwierigkeit dynamisch.
func get_difficulty() -> float:
	return PuzzleDifficulty.calculate(self)


## Setzt das Puzzle auf den Ausgangszustand zurück.
func reset() -> void:
	if _solved_grid != null:
		grid = _solved_grid.duplicate_grid()


## Speichert den aktuellen Zustand als gelösten Zustand.
func store_solved_state() -> void:
	_solved_grid = grid.duplicate_grid()


## Prüft ob das Puzzle aktuell gelöst ist.
func is_solved() -> bool:
	return PuzzleSolver.is_solved(self)


## Serialisiert zu JSON-Dictionary.
func to_json() -> Dictionary:
	var tiles_array: Array[String] = []

	for i in range(grid.get_tile_count()):
		var tile := grid.tiles[i]
		if tile != null:
			tiles_array.append(tile.to_string_format())
		else:
			tiles_array.append("empty")

	return {
		"id": id,
		"grid_width": grid.width,
		"grid_height": grid.height,
		"tiles": tiles_array,
	}


## Erstellt PuzzleDefinition aus JSON-Dictionary.
static func from_json(data: Dictionary) -> PuzzleDefinition:
	var width: int = data.get("grid_width", 4)
	var height: int = data.get("grid_height", 4)
	var tiles_array: Array = data.get("tiles", [])

	var grid_def := GridDefinition.new(width, height)

	for i in range(tiles_array.size()):
		var tile_string: String = tiles_array[i]
		if tile_string != "empty":
			var pos := grid_def.index_to_position(i)
			var tile := TileDefinition.from_string_format(tile_string)
			grid_def.set_tile_at(pos, tile)

	var puzzle := PuzzleDefinition.new(grid_def)
	puzzle.id = data.get("id", "")

	return puzzle
