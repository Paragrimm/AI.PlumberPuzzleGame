# Phase 2: Grid-Domain

## Ziel
Grid-Datenstruktur und UI-Komponente erstellen, die Tiles in einem 2D-Raster verwaltet.

---

## Dateien

### 2.1 `domains/grid/grid_definition.gd`

**Zweck:** Custom Resource für Grid-Daten

```gdscript
class_name GridDefinition
extends Resource


## Breite des Grids (Anzahl Spalten)
@export var width: int = 4

## Höhe des Grids (Anzahl Zeilen)
@export var height: int = 4

## 2D-Array der Tiles (flach gespeichert, row-major order)
## Index = y * width + x
@export var tiles: Array[TileDefinition] = []


func _init(initial_width: int = 4, initial_height: int = 4) -> void:
    width = initial_width
    height = initial_height
    _initialize_empty_grid()


func _initialize_empty_grid() -> void:
    tiles.clear()
    tiles.resize(width * height)


## Gibt das Tile an Position (x, y) zurück
func get_tile_at(position: Vector2i) -> TileDefinition:
    if not is_valid_position(position):
        return null
    
    var index := _position_to_index(position)
    return tiles[index]


## Setzt das Tile an Position (x, y)
func set_tile_at(position: Vector2i, tile: TileDefinition) -> void:
    if not is_valid_position(position):
        push_error("Invalid grid position: %s" % position)
        return
    
    var index := _position_to_index(position)
    tiles[index] = tile


## Prüft ob eine Position innerhalb des Grids liegt
func is_valid_position(position: Vector2i) -> bool:
    return position.x >= 0 and position.x < width and position.y >= 0 and position.y < height


## Konvertiert 2D-Position zu Array-Index
func _position_to_index(position: Vector2i) -> int:
    return position.y * width + position.x


## Konvertiert Array-Index zu 2D-Position
func _index_to_position(index: int) -> Vector2i:
    return Vector2i(index % width, index / width)


## Gibt alle gültigen Nachbar-Positionen zurück
func get_neighbor_positions(position: Vector2i) -> Array[Vector2i]:
    var neighbors: Array[Vector2i] = []
    var offsets := [
        Vector2i(0, -1),  # TOP
        Vector2i(1, 0),   # RIGHT
        Vector2i(0, 1),   # BOTTOM
        Vector2i(-1, 0),  # LEFT
    ]
    
    for offset in offsets:
        var neighbor_pos := position + offset
        if is_valid_position(neighbor_pos):
            neighbors.append(neighbor_pos)
    
    return neighbors


## Findet die Position des Start-Tiles
func find_start_position() -> Vector2i:
    for i in range(tiles.size()):
        if tiles[i] != null and tiles[i].type == TileType.Type.START:
            return _index_to_position(i)
    
    return Vector2i(-1, -1)  # Nicht gefunden


## Findet die Position des End-Tiles
func find_end_position() -> Vector2i:
    for i in range(tiles.size()):
        if tiles[i] != null and tiles[i].type == TileType.Type.END:
            return _index_to_position(i)
    
    return Vector2i(-1, -1)  # Nicht gefunden


## Erstellt eine tiefe Kopie des Grids
func duplicate_grid() -> GridDefinition:
    var copy := GridDefinition.new(width, height)
    for i in range(tiles.size()):
        if tiles[i] != null:
            copy.tiles[i] = tiles[i].duplicate_tile()
    return copy


## Iteriert über alle Tiles mit Position
func for_each_tile(callback: Callable) -> void:
    for i in range(tiles.size()):
        var position := _index_to_position(i)
        callback.call(position, tiles[i])
```

---

### 2.2 `domains/grid/grid_logic.gd`

**Zweck:** Hilfsklasse für Grid-Operationen und Nachbar-Ermittlung

```gdscript
class_name GridLogic


## Mapping von Richtung zu Offset
const DIRECTION_OFFSETS := {
    TileConnection.Side.TOP: Vector2i(0, -1),
    TileConnection.Side.RIGHT: Vector2i(1, 0),
    TileConnection.Side.BOTTOM: Vector2i(0, 1),
    TileConnection.Side.LEFT: Vector2i(-1, 0),
}


## Gibt die Richtung von Position A zu Position B zurück
static func get_direction_between(from: Vector2i, to: Vector2i) -> TileConnection.Side:
    var offset := to - from
    
    for direction in DIRECTION_OFFSETS:
        if DIRECTION_OFFSETS[direction] == offset:
            return direction
    
    # Sollte nicht passieren bei benachbarten Positionen
    push_error("Positions are not neighbors: %s -> %s" % [from, to])
    return TileConnection.Side.TOP


## Gibt die Nachbar-Position in einer bestimmten Richtung zurück
static func get_neighbor_in_direction(position: Vector2i, direction: TileConnection.Side) -> Vector2i:
    return position + DIRECTION_OFFSETS[direction]


## Prüft ob zwei Positionen benachbart sind
static func are_neighbors(pos_a: Vector2i, pos_b: Vector2i) -> bool:
    var diff := pos_b - pos_a
    return diff in DIRECTION_OFFSETS.values()


## Gibt alle vier Nachbar-Positionen zurück (auch ungültige)
static func get_all_neighbor_positions(position: Vector2i) -> Dictionary:
    var neighbors := {}
    for direction in DIRECTION_OFFSETS:
        neighbors[direction] = position + DIRECTION_OFFSETS[direction]
    return neighbors
```

---

### 2.3 `domains/grid/grid_view.gd`

**Zweck:** UI-Script für Grid-Darstellung

```gdscript
class_name GridView
extends GridContainer


## Signal wenn ein Tile im Grid angeklickt wird
signal tile_clicked(position: Vector2i)

## Signal wenn sich das Grid geändert hat
signal grid_updated


## Die Grid-Definition, die dieses View darstellt
var grid_definition: GridDefinition:
    set = set_grid_definition


## Referenz zur Tile-Szene
@export var tile_scene: PackedScene


## Cache für TileView-Instanzen
var _tile_views: Dictionary = {}  # Vector2i -> TileView


func set_grid_definition(value: GridDefinition) -> void:
    grid_definition = value
    if is_inside_tree():
        _rebuild_grid()


func _ready() -> void:
    if grid_definition != null:
        _rebuild_grid()


func _rebuild_grid() -> void:
    # Alte Tiles entfernen
    for child in get_children():
        child.queue_free()
    _tile_views.clear()
    
    if grid_definition == null:
        return
    
    # GridContainer konfigurieren
    columns = grid_definition.width
    
    # Tiles erstellen
    for y in range(grid_definition.height):
        for x in range(grid_definition.width):
            var position := Vector2i(x, y)
            var tile_view := _create_tile_view(position)
            add_child(tile_view)
            _tile_views[position] = tile_view


func _create_tile_view(position: Vector2i) -> TileView:
    var tile_view: TileView
    
    if tile_scene != null:
        tile_view = tile_scene.instantiate() as TileView
    else:
        # Fallback: Programmatisch erstellen
        tile_view = TileView.new()
    
    tile_view.grid_position = position
    tile_view.tile_definition = grid_definition.get_tile_at(position)
    tile_view.tile_clicked.connect(_on_tile_clicked.bind(position))
    
    return tile_view


func _on_tile_clicked(position: Vector2i) -> void:
    tile_clicked.emit(position)


## Aktualisiert die Anzeige eines einzelnen Tiles
func update_tile_at(position: Vector2i) -> void:
    if position in _tile_views:
        var tile_view: TileView = _tile_views[position]
        tile_view.tile_definition = grid_definition.get_tile_at(position)
        tile_view.on_tile_rotated()


## Aktualisiert alle Tiles
func refresh_all_tiles() -> void:
    for position in _tile_views:
        update_tile_at(position)
    grid_updated.emit()


## Gibt das TileView an einer Position zurück
func get_tile_view_at(position: Vector2i) -> TileView:
    return _tile_views.get(position, null)
```

---

### 2.4 `domains/grid/grid.tscn`

**Zweck:** Szene für Grid-UI

```
Struktur:
- GridContainer (Root, script: grid_view.gd)
  - (Tiles werden dynamisch hinzugefügt)

Eigenschaften:
- theme_override_constants/h_separation: 4
- theme_override_constants/v_separation: 4
- tile_scene: Referenz auf tile.tscn
```

---

## Verifikation

### Tests nach Phase 2:

1. **GridDefinition erstellen und Tiles setzen:**
```gdscript
var grid := GridDefinition.new(4, 4)
var tile := TileDefinition.new(TileType.Type.CORNER, 0)
grid.set_tile_at(Vector2i(1, 1), tile)

var retrieved := grid.get_tile_at(Vector2i(1, 1))
assert(retrieved == tile)
```

2. **Nachbar-Ermittlung:**
```gdscript
var grid := GridDefinition.new(4, 4)
var neighbors := grid.get_neighbor_positions(Vector2i(0, 0))
# Erwartung: [Vector2i(1, 0), Vector2i(0, 1)] (nur rechts und unten)

neighbors = grid.get_neighbor_positions(Vector2i(1, 1))
# Erwartung: 4 Nachbarn (alle Richtungen)
```

3. **Richtungsermittlung:**
```gdscript
var direction := GridLogic.get_direction_between(Vector2i(1, 1), Vector2i(2, 1))
assert(direction == TileConnection.Side.RIGHT)
```

4. **Grid-View visuell testen:**
- grid.tscn im Editor öffnen
- GridDefinition zuweisen
- Tiles sollten im 4x4 Raster erscheinen
- Klick auf Tile sollte Signal auslösen

---

## Abhängigkeiten

- Phase 1: Tile-Domain (TileDefinition, TileType, TileConnection, TileView)
