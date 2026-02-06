extends Node
## Speichert Fortschritt persistent (Autoload).

## Pfad zur Speicherdatei.
const SAVE_PATH := "user://progress.json"

## Anzahl gelöster Puzzles.
var puzzles_solved: int = 0

## Beste Züge pro Puzzle-ID.
var best_moves: Dictionary = {}  # puzzle_id -> int

## Gesamtanzahl Züge.
var total_moves: int = 0


func _ready() -> void:
	load_progress()


## Markiert ein Puzzle als gelöst.
func mark_puzzle_solved(puzzle_id: String, moves: int) -> void:
	puzzles_solved += 1
	total_moves += moves

	# Beste Züge tracken
	if puzzle_id not in best_moves or moves < best_moves[puzzle_id]:
		best_moves[puzzle_id] = moves

	save_progress()


## Gibt die besten Züge für ein Puzzle zurück (-1 wenn nicht gelöst).
func get_best_moves(puzzle_id: String) -> int:
	return best_moves.get(puzzle_id, -1)


## Speichert den Fortschritt.
func save_progress() -> void:
	var data := {
		"puzzles_solved": puzzles_solved,
		"best_moves": best_moves,
		"total_moves": total_moves,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not save progress: %s" % FileAccess.get_open_error())
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Lädt den Fortschritt.
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load progress: %s" % FileAccess.get_open_error())
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("Could not parse progress file: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	puzzles_solved = data.get("puzzles_solved", 0)
	best_moves = data.get("best_moves", {})
	total_moves = data.get("total_moves", 0)


## Setzt den Fortschritt zurück.
func reset_progress() -> void:
	puzzles_solved = 0
	best_moves.clear()
	total_moves = 0
	save_progress()
