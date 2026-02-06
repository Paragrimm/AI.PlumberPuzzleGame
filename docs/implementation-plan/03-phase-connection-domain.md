# Phase 3: Connection-Domain

## Ziel
Verbindungslogik implementieren, die prüft ob Tiles miteinander verbunden sind und Pfade zwischen Start und Ende findet.

---

## Dateien

### 3.1 `domains/connection/connection_checker.gd`

**Zweck:** Prüft Verbindungen zwischen benachbarten Tiles

```gdscript
class_name ConnectionChecker


## Prüft ob zwei benachbarte Tiles miteinander verbunden sind
## Gibt true zurück wenn beide Tiles eine Verbindung zur jeweils anderen Seite haben
static func are_tiles_connected(
    grid: GridDefinition,
    position_a: Vector2i,
    position_b: Vector2i
) -> bool:
    # Prüfen ob Positionen gültig sind
    if not grid.is_valid_position(position_a) or not grid.is_valid_position(position_b):
        return false
    
    # Prüfen ob Positionen benachbart sind
    if not GridLogic.are_neighbors(position_a, position_b):
        return false
    
    var tile_a := grid.get_tile_at(position_a)
    var tile_b := grid.get_tile_at(position_b)
    
    # Null-Tiles haben keine Verbindung
    if tile_a == null or tile_b == null:
        return false
    
    # Richtung von A nach B ermitteln
    var direction_a_to_b := GridLogic.get_direction_between(position_a, position_b)
    var direction_b_to_a := TileConnection.get_opposite_side(direction_a_to_b)
    
    # Prüfen ob beide Tiles die entsprechende Verbindung haben
    var a_connects := TileConnection.has_connection_at_side(tile_a, direction_a_to_b)
    var b_connects := TileConnection.has_connection_at_side(tile_b, direction_b_to_a)
    
    return a_connects and b_connects


## Gibt alle Positionen zurück, die mit einer gegebenen Position verbunden sind
static func get_connected_neighbors(grid: GridDefinition, position: Vector2i) -> Array[Vector2i]:
    var connected: Array[Vector2i] = []
    var neighbors := grid.get_neighbor_positions(position)
    
    for neighbor_pos in neighbors:
        if are_tiles_connected(grid, position, neighbor_pos):
            connected.append(neighbor_pos)
    
    return connected


## Zählt die Anzahl der aktiven Verbindungen eines Tiles
static func count_connections(grid: GridDefinition, position: Vector2i) -> int:
    return get_connected_neighbors(grid, position).size()


## Gibt alle Verbindungen im gesamten Grid zurück (als Array von Position-Paaren)
static func get_all_connections(grid: GridDefinition) -> Array:
    var connections: Array = []
    var checked_pairs: Dictionary = {}
    
    grid.for_each_tile(func(position: Vector2i, tile: TileDefinition) -> void:
        if tile == null:
            return
        
        var neighbors := grid.get_neighbor_positions(position)
        for neighbor_pos in neighbors:
            # Nur einmal pro Paar prüfen
            var pair_key := _make_pair_key(position, neighbor_pos)
            if pair_key in checked_pairs:
                continue
            checked_pairs[pair_key] = true
            
            if are_tiles_connected(grid, position, neighbor_pos):
                connections.append([position, neighbor_pos])
    )
    
    return connections


## Erstellt einen eindeutigen Key für ein Positionspaar
static func _make_pair_key(pos_a: Vector2i, pos_b: Vector2i) -> String:
    # Sortieren damit (a,b) und (b,a) den gleichen Key haben
    if pos_a.x < pos_b.x or (pos_a.x == pos_b.x and pos_a.y < pos_b.y):
        return "%d,%d-%d,%d" % [pos_a.x, pos_a.y, pos_b.x, pos_b.y]
    else:
        return "%d,%d-%d,%d" % [pos_b.x, pos_b.y, pos_a.x, pos_a.y]
```

---

### 3.2 `domains/connection/path_finder.gd`

**Zweck:** Findet Pfade von Start zu Ende mittels BFS

```gdscript
class_name PathFinder


## Ergebnis einer Pfadsuche
class PathResult:
    ## Ob ein Pfad gefunden wurde
    var found: bool = false
    
    ## Der Pfad als Array von Positionen (inklusive Start und Ende)
    var path: Array[Vector2i] = []
    
    ## Alle besuchten Positionen während der Suche
    var visited: Array[Vector2i] = []


## Findet den kürzesten Pfad von Start zu Ende
## Verwendet Breadth-First Search (BFS)
static func find_path(grid: GridDefinition) -> PathResult:
    var result := PathResult.new()
    
    var start_pos := grid.find_start_position()
    var end_pos := grid.find_end_position()
    
    # Prüfen ob Start und Ende existieren
    if start_pos == Vector2i(-1, -1) or end_pos == Vector2i(-1, -1):
        return result
    
    # BFS initialisieren
    var queue: Array[Vector2i] = [start_pos]
    var visited: Dictionary = {start_pos: true}
    var came_from: Dictionary = {}  # Position -> vorherige Position
    
    while queue.size() > 0:
        var current := queue.pop_front()
        result.visited.append(current)
        
        # Ziel erreicht?
        if current == end_pos:
            result.found = true
            result.path = _reconstruct_path(came_from, start_pos, end_pos)
            return result
        
        # Verbundene Nachbarn besuchen
        var connected := ConnectionChecker.get_connected_neighbors(grid, current)
        for neighbor in connected:
            if neighbor not in visited:
                visited[neighbor] = true
                came_from[neighbor] = current
                queue.append(neighbor)
    
    # Kein Pfad gefunden
    return result


## Rekonstruiert den Pfad aus der came_from-Map
static func _reconstruct_path(
    came_from: Dictionary,
    start: Vector2i,
    end: Vector2i
) -> Array[Vector2i]:
    var path: Array[Vector2i] = [end]
    var current := end
    
    while current != start:
        current = came_from[current]
        path.insert(0, current)
    
    return path


## Prüft ob das Puzzle gelöst ist (Start und Ende sind verbunden)
static func is_puzzle_solved(grid: GridDefinition) -> bool:
    var result := find_path(grid)
    return result.found


## Findet alle vom Start aus erreichbaren Positionen
static func find_reachable_from_start(grid: GridDefinition) -> Array[Vector2i]:
    var start_pos := grid.find_start_position()
    if start_pos == Vector2i(-1, -1):
        return []
    
    return _flood_fill(grid, start_pos)


## Flood-Fill von einer Startposition aus
static func _flood_fill(grid: GridDefinition, start: Vector2i) -> Array[Vector2i]:
    var reachable: Array[Vector2i] = []
    var queue: Array[Vector2i] = [start]
    var visited: Dictionary = {start: true}
    
    while queue.size() > 0:
        var current := queue.pop_front()
        reachable.append(current)
        
        var connected := ConnectionChecker.get_connected_neighbors(grid, current)
        for neighbor in connected:
            if neighbor not in visited:
                visited[neighbor] = true
                queue.append(neighbor)
    
    return reachable
```

---

## Verifikation

### Tests nach Phase 3:

1. **Verbindungsprüfung zwischen zwei Tiles:**
```gdscript
var grid := GridDefinition.new(2, 1)

# Zwei gerade Tiles horizontal verbunden
var tile_left := TileDefinition.new(TileType.Type.STRAIGHT, 90)  # links-rechts
var tile_right := TileDefinition.new(TileType.Type.STRAIGHT, 90) # links-rechts
grid.set_tile_at(Vector2i(0, 0), tile_left)
grid.set_tile_at(Vector2i(1, 0), tile_right)

var connected := ConnectionChecker.are_tiles_connected(grid, Vector2i(0, 0), Vector2i(1, 0))
assert(connected == true)

# Jetzt mit nicht passender Rotation
tile_right.rotation_degrees = 0  # oben-unten
connected = ConnectionChecker.are_tiles_connected(grid, Vector2i(0, 0), Vector2i(1, 0))
assert(connected == false)
```

2. **Pfadsuche in einfachem Grid:**
```gdscript
var grid := GridDefinition.new(3, 1)

# START -> STRAIGHT -> END
grid.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.START, 90))
grid.set_tile_at(Vector2i(1, 0), TileDefinition.new(TileType.Type.STRAIGHT, 90))
grid.set_tile_at(Vector2i(2, 0), TileDefinition.new(TileType.Type.END, 270))

var result := PathFinder.find_path(grid)
assert(result.found == true)
assert(result.path.size() == 3)
```

3. **Kein Pfad wenn nicht verbunden:**
```gdscript
var grid := GridDefinition.new(3, 1)

# START -> STRAIGHT (falsche Richtung) -> END
grid.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.START, 90))
grid.set_tile_at(Vector2i(1, 0), TileDefinition.new(TileType.Type.STRAIGHT, 0))  # oben-unten
grid.set_tile_at(Vector2i(2, 0), TileDefinition.new(TileType.Type.END, 270))

var result := PathFinder.find_path(grid)
assert(result.found == false)
```

4. **Visuelle Verifikation:**
- Debug-Ausgabe der Verbindungen im Grid
- Gefundenen Pfad visualisieren (z.B. Tiles einfärben)

---

## Abhängigkeiten

- Phase 1: Tile-Domain (TileDefinition, TileType, TileConnection)
- Phase 2: Grid-Domain (GridDefinition, GridLogic)
