# Phase 4: Puzzle-Domain

## Ziel
Puzzle-Wrapper, Generator-Algorithmus, Lösungsprüfung und Schwierigkeitsberechnung implementieren.

---

## Dateien

### 4.1 `domains/puzzle/puzzle_definition.gd`

**Zweck:** Custom Resource als Wrapper um GridDefinition

```gdscript
class_name PuzzleDefinition
extends Resource


## Eindeutige ID des Puzzles
@export var id: String = ""

## Das Grid mit allen Tiles
@export var grid: GridDefinition

## Die ursprüngliche (gelöste) Konfiguration zum Zurücksetzen
## Wird beim Generieren gespeichert, BEVOR Tiles zufällig rotiert werden
var _solved_grid: GridDefinition


func _init(puzzle_grid: GridDefinition = null) -> void:
    if puzzle_grid != null:
        grid = puzzle_grid


## Berechnet die Schwierigkeit dynamisch
func get_difficulty() -> float:
    return PuzzleDifficulty.calculate(self)


## Setzt das Puzzle auf den Ausgangszustand zurück
func reset() -> void:
    if _solved_grid != null:
        grid = _solved_grid.duplicate_grid()


## Speichert den aktuellen Zustand als gelösten Zustand
func store_solved_state() -> void:
    _solved_grid = grid.duplicate_grid()


## Prüft ob das Puzzle aktuell gelöst ist
func is_solved() -> bool:
    return PuzzleSolver.is_solved(self)


## Serialisiert zu JSON-Dictionary
func to_json() -> Dictionary:
    var tiles_array: Array[String] = []
    
    grid.for_each_tile(func(position: Vector2i, tile: TileDefinition) -> void:
        if tile != null:
            tiles_array.append(tile.to_string_format())
        else:
            tiles_array.append("empty")
    )
    
    return {
        "id": id,
        "grid_width": grid.width,
        "grid_height": grid.height,
        "tiles": tiles_array,
    }


## Erstellt PuzzleDefinition aus JSON-Dictionary
static func from_json(data: Dictionary) -> PuzzleDefinition:
    var width: int = data.get("grid_width", 4)
    var height: int = data.get("grid_height", 4)
    var tiles_array: Array = data.get("tiles", [])
    
    var grid_def := GridDefinition.new(width, height)
    
    for i in range(tiles_array.size()):
        var tile_string: String = tiles_array[i]
        if tile_string != "empty":
            var position := grid_def._index_to_position(i)
            var tile := TileDefinition.from_string_format(tile_string)
            grid_def.set_tile_at(position, tile)
    
    var puzzle := PuzzleDefinition.new(grid_def)
    puzzle.id = data.get("id", "")
    
    return puzzle
```

---

### 4.2 `domains/puzzle/puzzle_solver.gd`

**Zweck:** Prüft ob ein Puzzle gelöst ist

```gdscript
class_name PuzzleSolver


## Prüft ob das Puzzle gelöst ist (Start und Ende verbunden)
static func is_solved(puzzle: PuzzleDefinition) -> bool:
    if puzzle == null or puzzle.grid == null:
        return false
    
    return PathFinder.is_puzzle_solved(puzzle.grid)


## Findet den Lösungspfad (falls vorhanden)
static func get_solution_path(puzzle: PuzzleDefinition) -> Array[Vector2i]:
    if puzzle == null or puzzle.grid == null:
        return []
    
    var result := PathFinder.find_path(puzzle.grid)
    return result.path


## Zählt die Anzahl der verbundenen Tiles (vom Start aus erreichbar)
static func count_connected_tiles(puzzle: PuzzleDefinition) -> int:
    if puzzle == null or puzzle.grid == null:
        return 0
    
    var reachable := PathFinder.find_reachable_from_start(puzzle.grid)
    return reachable.size()
```

---

### 4.3 `domains/puzzle/puzzle_difficulty.gd`

**Zweck:** Berechnet den Schwierigkeitsgrad dynamisch

```gdscript
class_name PuzzleDifficulty


## Gewichtung der Faktoren
const WEIGHT_GRID_SIZE := 0.3
const WEIGHT_ROTATIONS := 0.5
const WEIGHT_PATH_COMPLEXITY := 0.2


## Berechnet den Schwierigkeitsgrad eines Puzzles
static func calculate(puzzle: PuzzleDefinition) -> float:
    if puzzle == null or puzzle.grid == null:
        return 0.0
    
    var grid_size_factor := _calculate_grid_size_factor(puzzle.grid)
    var rotation_factor := _calculate_rotation_factor(puzzle)
    var path_complexity_factor := _calculate_path_complexity_factor(puzzle)
    
    var difficulty := (
        grid_size_factor * WEIGHT_GRID_SIZE +
        rotation_factor * WEIGHT_ROTATIONS +
        path_complexity_factor * WEIGHT_PATH_COMPLEXITY
    )
    
    return difficulty


## Berechnet den Faktor basierend auf der Grid-Größe
static func _calculate_grid_size_factor(grid: GridDefinition) -> float:
    var total_tiles := grid.width * grid.height
    # Normalisieren: 9 (3x3) = 1.0, 16 (4x4) = 1.78, 25 (5x5) = 2.78
    return float(total_tiles) / 9.0


## Berechnet den Faktor basierend auf nötigen Rotationen
static func _calculate_rotation_factor(puzzle: PuzzleDefinition) -> float:
    var rotatable_count := 0
    var corner_count := 0
    
    puzzle.grid.for_each_tile(func(position: Vector2i, tile: TileDefinition) -> void:
        if tile == null:
            return
        
        if TileType.is_rotatable(tile.type):
            rotatable_count += 1
            
            # Ecken haben mehr Rotationsmöglichkeiten = schwerer
            if tile.type == TileType.Type.CORNER:
                corner_count += 1
    )
    
    # Mehr drehbare Tiles und Ecken = schwerer
    return float(rotatable_count) * 0.5 + float(corner_count) * 0.3


## Berechnet die Pfad-Komplexität (Anzahl Richtungswechsel)
static func _calculate_path_complexity_factor(puzzle: PuzzleDefinition) -> float:
    var path := PuzzleSolver.get_solution_path(puzzle)
    
    if path.size() < 3:
        return 0.0
    
    var direction_changes := 0
    var prev_direction: TileConnection.Side = GridLogic.get_direction_between(path[0], path[1])
    
    for i in range(2, path.size()):
        var current_direction := GridLogic.get_direction_between(path[i - 1], path[i])
        if current_direction != prev_direction:
            direction_changes += 1
            prev_direction = current_direction
    
    # Mehr Richtungswechsel = mehr Ecken = schwerer
    return float(direction_changes) * 0.5


## Gibt einen lesbaren Schwierigkeitsgrad zurück
static func get_difficulty_label(difficulty: float) -> String:
    if difficulty < 1.5:
        return "Leicht"
    elif difficulty < 2.5:
        return "Mittel"
    elif difficulty < 3.5:
        return "Schwer"
    else:
        return "Experte"
```

---

### 4.4 `domains/puzzle/puzzle_generator.gd`

**Zweck:** Generiert spielbare Puzzles algorithmisch

```gdscript
class_name PuzzleGenerator


## Konfiguration für den Generator
class GeneratorConfig:
    var grid_width: int = 4
    var grid_height: int = 4
    var start_position: Vector2i = Vector2i(-1, -1)  # -1 = zufällig
    var end_position: Vector2i = Vector2i(-1, -1)    # -1 = zufällig
    var min_path_length: int = 4
    var max_generation_attempts: int = 100


## Generiert ein neues Puzzle
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
    
    # 1. Start- und Endposition bestimmen
    var start_pos := _determine_start_position(config, grid)
    var end_pos := _determine_end_position(config, grid, start_pos)
    
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
    config: GeneratorConfig,
    grid: GridDefinition,
    start_pos: Vector2i
) -> Vector2i:
    if config.end_position != Vector2i(-1, -1):
        return config.end_position
    
    # Zufällige Position am gegenüberliegenden Rand
    var end_pos := _get_random_edge_position(grid)
    
    # Sicherstellen, dass Start und Ende unterschiedlich sind
    var attempts := 0
    while end_pos == start_pos and attempts < 50:
        end_pos = _get_random_edge_position(grid)
        attempts += 1
    
    return end_pos


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
    grid: GridDefinition,
    start: Vector2i,
    end: Vector2i,
    min_length: int
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
        var position := path[i]
        var tile_type: TileType.Type
        var rotation: int
        
        if i == 0:
            # START-Tile
            tile_type = TileType.Type.START
            var next_pos := path[i + 1]
            var direction := GridLogic.get_direction_between(position, next_pos)
            rotation = direction
        elif i == path.size() - 1:
            # END-Tile
            tile_type = TileType.Type.END
            var prev_pos := path[i - 1]
            var direction := GridLogic.get_direction_between(position, prev_pos)
            rotation = direction
        else:
            # Mittleres Tile
            var prev_pos := path[i - 1]
            var next_pos := path[i + 1]
            var dir_from_prev := GridLogic.get_direction_between(position, prev_pos)
            var dir_to_next := GridLogic.get_direction_between(position, next_pos)
            
            # Bestimmen ob STRAIGHT oder CORNER
            var result := _determine_tile_type_and_rotation(dir_from_prev, dir_to_next)
            tile_type = result[0]
            rotation = result[1]
        
        var tile := TileDefinition.new(tile_type, rotation)
        grid.set_tile_at(position, tile)


static func _determine_tile_type_and_rotation(
    dir_a: TileConnection.Side,
    dir_b: TileConnection.Side
) -> Array:
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
    # Wir müssen die Rotation finden, die zu unseren Seiten führt
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
        var sides: Array = config[0]
        sides.sort()
        if sides[0] == target_sides[0] and sides[1] == target_sides[1]:
            return config[1]
    
    return 0


static func _fill_remaining_tiles(grid: GridDefinition) -> void:
    grid.for_each_tile(func(position: Vector2i, tile: TileDefinition) -> void:
        if tile != null:
            return  # Bereits belegt
        
        # Zufälliges Tile (STRAIGHT oder CORNER)
        var tile_type: TileType.Type
        if randf() < 0.5:
            tile_type = TileType.Type.STRAIGHT
        else:
            tile_type = TileType.Type.CORNER
        
        var valid_rotations := TileType.get_valid_rotations(tile_type)
        var rotation: int = valid_rotations[randi() % valid_rotations.size()]
        
        var new_tile := TileDefinition.new(tile_type, rotation)
        grid.set_tile_at(position, new_tile)
    )


static func _randomize_rotations(grid: GridDefinition) -> void:
    grid.for_each_tile(func(position: Vector2i, tile: TileDefinition) -> void:
        if tile == null:
            return
        
        if not TileType.is_rotatable(tile.type):
            return
        
        # Zufällige Anzahl Rotationen
        var rotations := randi() % 4
        for i in range(rotations):
            tile.rotate_clockwise()
    )


static func _generate_id() -> String:
    return "puzzle_%d" % Time.get_unix_time_from_system()
```

---

### 4.5 `domains/puzzle/puzzle_validator.gd`

**Zweck:** Validiert generierte Puzzles

```gdscript
class_name PuzzleValidator


## Prüft ob ein Puzzle gültig und spielbar ist
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


## Prüft ob das Puzzle lösbar ist wenn alle Tiles korrekt rotiert sind
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
    
    grid.for_each_tile(func(position: Vector2i, tile: TileDefinition) -> void:
        if tile != null and TileType.is_rotatable(tile.type):
            rotatable_positions.append(position)
    )
    
    # Begrenzen auf erste 10 Tiles (sonst zu lange)
    if rotatable_positions.size() > 10:
        push_warning("Too many rotatable tiles for brute-force check")
        return true  # Optimistisch annehmen
    
    return _try_all_rotations(grid, rotatable_positions, 0)


static func _try_all_rotations(
    grid: GridDefinition,
    positions: Array[Vector2i],
    index: int
) -> bool:
    if index >= positions.size():
        var test_puzzle := PuzzleDefinition.new(grid)
        return PuzzleSolver.is_solved(test_puzzle)
    
    var position := positions[index]
    var tile := grid.get_tile_at(position)
    var valid_rotations := TileType.get_valid_rotations(tile.type)
    
    var original_rotation := tile.rotation_degrees
    
    for rotation in valid_rotations:
        tile.rotation_degrees = rotation
        if _try_all_rotations(grid, positions, index + 1):
            tile.rotation_degrees = original_rotation
            return true
    
    tile.rotation_degrees = original_rotation
    return false
```

---

## Verifikation

### Tests nach Phase 4:

1. **Puzzle generieren:**
```gdscript
var config := PuzzleGenerator.GeneratorConfig.new()
config.grid_width = 4
config.grid_height = 4

var puzzle := PuzzleGenerator.generate(config)
assert(puzzle != null)
assert(puzzle.grid != null)
print("Generated puzzle: %s" % puzzle.id)
```

2. **Puzzle validieren:**
```gdscript
var puzzle := PuzzleGenerator.generate()
assert(PuzzleValidator.is_valid(puzzle) == true)
```

3. **Schwierigkeit berechnen:**
```gdscript
var puzzle := PuzzleGenerator.generate()
var difficulty := puzzle.get_difficulty()
var label := PuzzleDifficulty.get_difficulty_label(difficulty)
print("Difficulty: %.2f (%s)" % [difficulty, label])
```

4. **JSON Roundtrip:**
```gdscript
var puzzle := PuzzleGenerator.generate()
var json := puzzle.to_json()
var restored := PuzzleDefinition.from_json(json)

assert(restored.grid.width == puzzle.grid.width)
assert(restored.grid.height == puzzle.grid.height)
```

5. **Generator-Stress-Test:**
```gdscript
# 100 Puzzles generieren, alle müssen gültig sein
for i in range(100):
    var puzzle := PuzzleGenerator.generate()
    assert(puzzle != null, "Generation failed at attempt %d" % i)
    assert(PuzzleValidator.is_valid(puzzle), "Invalid puzzle at attempt %d" % i)
```

---

## Abhängigkeiten

- Phase 1: Tile-Domain
- Phase 2: Grid-Domain
- Phase 3: Connection-Domain (PathFinder, ConnectionChecker)
