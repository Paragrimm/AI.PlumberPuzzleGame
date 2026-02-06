# Phase 6: Polish

## Ziel
Fortschritts-Tracking, visuelle Verbesserungen und JSON-Export/Import implementieren.

---

## Dateien

### 6.1 `game/progress_tracker.gd`

**Zweck:** Speichert Fortschritt persistent (Autoload)

```gdscript
class_name ProgressTracker
extends Node


## Pfad zur Speicherdatei
const SAVE_PATH := "user://progress.json"


## Anzahl gelöster Puzzles
var puzzles_solved: int = 0

## Beste Züge pro Puzzle-ID
var best_moves: Dictionary = {}  # puzzle_id -> int

## Gesamtanzahl Züge
var total_moves: int = 0


func _ready() -> void:
    load_progress()


## Markiert ein Puzzle als gelöst
func mark_puzzle_solved(puzzle_id: String, moves: int) -> void:
    puzzles_solved += 1
    total_moves += moves
    
    # Beste Züge tracken
    if puzzle_id not in best_moves or moves < best_moves[puzzle_id]:
        best_moves[puzzle_id] = moves
    
    save_progress()


## Gibt die besten Züge für ein Puzzle zurück (-1 wenn nicht gelöst)
func get_best_moves(puzzle_id: String) -> int:
    return best_moves.get(puzzle_id, -1)


## Speichert den Fortschritt
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


## Lädt den Fortschritt
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


## Setzt den Fortschritt zurück
func reset_progress() -> void:
    puzzles_solved = 0
    best_moves.clear()
    total_moves = 0
    save_progress()
```

**Autoload-Registrierung in project.godot:**
```
[autoload]
ProgressTracker="*res://game/progress_tracker.gd"
```

---

### 6.2 Erweiterung: `game/game_manager.gd`

**Ergänzungen für Progress-Tracking:**

```gdscript
# Ergänzung in _check_win_condition():
func _check_win_condition() -> void:
    if current_puzzle == null:
        return
    
    if current_puzzle.is_solved():
        is_solved = true
        
        # Fortschritt speichern
        ProgressTracker.mark_puzzle_solved(current_puzzle.id, move_count)
        
        puzzle_solved.emit()
```

---

### 6.3 Erweiterung: `ui/stats_display.gd`

**Ergänzungen für erweiterte Stats:**

```gdscript
# Neue Labels
@onready var _difficulty_label: Label = $DifficultyLabel
@onready var _best_moves_label: Label = $BestMovesLabel


func set_puzzle_info(puzzle: PuzzleDefinition) -> void:
    var difficulty := puzzle.get_difficulty()
    var label := PuzzleDifficulty.get_difficulty_label(difficulty)
    _difficulty_label.text = "Schwierigkeit: %s" % label
    
    var best := ProgressTracker.get_best_moves(puzzle.id)
    if best > 0:
        _best_moves_label.text = "Beste: %d" % best
        _best_moves_label.visible = true
    else:
        _best_moves_label.visible = false


func show_solved_message() -> void:
    _solved_label.visible = true
    _solved_label.text = "Gelöst!"
    
    # Gesamtstatistik anzeigen
    _solved_label.text += " (Gesamt: %d Puzzles)" % ProgressTracker.puzzles_solved
```

---

### 6.4 Visuelle Verbesserungen: `domains/tile/tile_view.gd`

**Ergänzungen für besseres Feedback:**

```gdscript
## Animiert die Rotation
func animate_rotation() -> void:
    if tile_definition == null:
        return
    
    var target_rotation := tile_definition.rotation_degrees
    var tween := create_tween()
    tween.tween_property(
        _connection_indicator,
        "rotation_degrees",
        target_rotation,
        0.15
    ).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Hebt das Tile hervor (z.B. wenn verbunden)
func set_highlighted(highlighted: bool) -> void:
    if highlighted:
        _background.modulate = Color(1.2, 1.2, 1.2)
    else:
        _background.modulate = Color.WHITE


## Zeigt an, ob das Tile Teil des Lösungspfads ist
func set_on_solution_path(on_path: bool) -> void:
    if on_path:
        # Subtiler Glow-Effekt
        _background.modulate = Color(1.0, 1.0, 0.8)
    else:
        _background.modulate = Color.WHITE
```

---

### 6.5 Erweiterung: `domains/grid/grid_view.gd`

**Ergänzungen für Pfad-Visualisierung:**

```gdscript
## Hebt den Lösungspfad hervor
func highlight_solution_path(path: Array[Vector2i]) -> void:
    # Erst alle zurücksetzen
    for position in _tile_views:
        var tile_view: TileView = _tile_views[position]
        tile_view.set_on_solution_path(false)
    
    # Dann Pfad hervorheben
    for position in path:
        if position in _tile_views:
            var tile_view: TileView = _tile_views[position]
            tile_view.set_on_solution_path(true)


## Hebt verbundene Tiles hervor
func highlight_connected_tiles() -> void:
    if grid_definition == null:
        return
    
    var reachable := PathFinder.find_reachable_from_start(grid_definition)
    
    for position in _tile_views:
        var tile_view: TileView = _tile_views[position]
        tile_view.set_highlighted(position in reachable)
```

---

### 6.6 JSON-Export-Utility

**`domains/puzzle/puzzle_exporter.gd`**

```gdscript
class_name PuzzleExporter


## Exportiert ein Puzzle als JSON-String
static func export_to_json_string(puzzle: PuzzleDefinition) -> String:
    var data := puzzle.to_json()
    return JSON.stringify(data, "\t")


## Importiert ein Puzzle aus JSON-String
static func import_from_json_string(json_string: String) -> PuzzleDefinition:
    var json := JSON.new()
    var error := json.parse(json_string)
    if error != OK:
        push_error("Invalid JSON: %s" % json.get_error_message())
        return null
    
    return PuzzleDefinition.from_json(json.data)


## Speichert Puzzle in Datei
static func save_to_file(puzzle: PuzzleDefinition, path: String) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Could not open file for writing: %s" % path)
        return false
    
    file.store_string(export_to_json_string(puzzle))
    file.close()
    return true


## Lädt Puzzle aus Datei
static func load_from_file(path: String) -> PuzzleDefinition:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Could not open file for reading: %s" % path)
        return null
    
    var json_string := file.get_as_text()
    file.close()
    
    return import_from_json_string(json_string)


## Generiert mehrere Puzzles und exportiert sie
static func batch_generate_and_export(
    count: int,
    config: PuzzleGenerator.GeneratorConfig,
    output_dir: String
) -> int:
    var success_count := 0
    
    DirAccess.make_dir_recursive_absolute(output_dir)
    
    for i in range(count):
        var puzzle := PuzzleGenerator.generate(config)
        if puzzle == null:
            continue
        
        var filename := "%s/puzzle_%03d.json" % [output_dir, i + 1]
        if save_to_file(puzzle, filename):
            success_count += 1
    
    return success_count
```

---

## Verifikation

### Tests nach Phase 6:

1. **Fortschritts-Tracking:**
```gdscript
# Puzzle lösen
# Spiel beenden und neu starten
# Fortschritt sollte geladen werden
print("Gelöste Puzzles: %d" % ProgressTracker.puzzles_solved)
```

2. **JSON-Export/Import:**
```gdscript
var puzzle := PuzzleGenerator.generate()
var json_string := PuzzleExporter.export_to_json_string(puzzle)
print(json_string)

var imported := PuzzleExporter.import_from_json_string(json_string)
assert(imported.grid.width == puzzle.grid.width)
```

3. **Datei-Export:**
```gdscript
var puzzle := PuzzleGenerator.generate()
PuzzleExporter.save_to_file(puzzle, "user://test_puzzle.json")

var loaded := PuzzleExporter.load_from_file("user://test_puzzle.json")
assert(loaded != null)
```

4. **Batch-Generierung:**
```gdscript
var config := PuzzleGenerator.GeneratorConfig.new()
config.grid_width = 4
config.grid_height = 4

var count := PuzzleExporter.batch_generate_and_export(10, config, "user://puzzles")
print("Generated %d puzzles" % count)
```

5. **Visuelle Tests:**
- Tile-Rotation sollte animiert sein
- Verbundene Tiles sollten hervorgehoben werden
- Lösungspfad sollte sichtbar sein nach Lösung

---

## Abhängigkeiten

- Alle vorherigen Phasen
- Godot File-System (FileAccess, DirAccess)
- JSON-Parser

---

## Zukünftige Erweiterungen (nicht in diesem Plan)

1. **Online-Puzzles:** HTTP-Request zum Laden von Puzzles vom Server
2. **Leaderboards:** Beste Züge online speichern
3. **Achievements:** Meilensteine freischalten
4. **Sound-Effekte:** Audio für Rotation, Lösung, etc.
5. **Themes:** Verschiedene visuelle Stile
6. **Tutorial:** Einführung für neue Spieler
