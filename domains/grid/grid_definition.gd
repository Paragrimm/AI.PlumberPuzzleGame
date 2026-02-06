class_name GridDefinition
extends Resource
## Repräsentiert die Datenstruktur eines Grids.
## Speichert Tiles in einem 2D-Array (flach, row-major order).

## Breite des Grids (Anzahl Spalten).
@export var width: int = 4

## Höhe des Grids (Anzahl Zeilen).
@export var height: int = 4

## Flaches Array der Tiles (Index = y * width + x).
@export var tiles: Array[TileDefinition] = []


func _init(initial_width: int = 4, initial_height: int = 4) -> void:
	width = initial_width
	height = initial_height
	_initialize_empty_grid()


## Initialisiert das Grid mit leeren (null) Tiles.
func _initialize_empty_grid() -> void:
	tiles.clear()
	tiles.resize(width * height)
	for i in range(tiles.size()):
		tiles[i] = null


## Gibt das Tile an der Position (x, y) zurück.
## Gibt null zurück wenn die Position ungültig ist.
func get_tile_at(position: Vector2i) -> TileDefinition:
	if not is_valid_position(position):
		return null

	var index := _position_to_index(position)
	return tiles[index]


## Setzt das Tile an der Position (x, y).
func set_tile_at(position: Vector2i, tile: TileDefinition) -> void:
	if not is_valid_position(position):
		push_error("Invalid grid position: %s" % position)
		return

	var index := _position_to_index(position)
	tiles[index] = tile


## Prüft ob eine Position innerhalb des Grids liegt.
func is_valid_position(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < width and position.y >= 0 and position.y < height


## Konvertiert eine 2D-Position zu einem Array-Index.
func _position_to_index(position: Vector2i) -> int:
	return position.y * width + position.x


## Konvertiert einen Array-Index zu einer 2D-Position.
func index_to_position(index: int) -> Vector2i:
	return Vector2i(index % width, index / width)


## Gibt alle gültigen Nachbar-Positionen einer Position zurück.
func get_neighbor_positions(position: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var offsets := [
		Vector2i(0, -1),  # TOP
		Vector2i(1, 0),  # RIGHT
		Vector2i(0, 1),  # BOTTOM
		Vector2i(-1, 0),  # LEFT
	]

	for offset in offsets:
		var neighbor_position: Vector2i = position + offset
		if is_valid_position(neighbor_position):
			neighbors.append(neighbor_position)

	return neighbors


## Findet die Position des Start-Tiles.
## Gibt Vector2i(-1, -1) zurück wenn kein Start gefunden wird.
func find_start_position() -> Vector2i:
	for i in range(tiles.size()):
		if tiles[i] != null and tiles[i].type == TileType.Type.START:
			return index_to_position(i)

	return Vector2i(-1, -1)


## Findet die Position des End-Tiles.
## Gibt Vector2i(-1, -1) zurück wenn kein Ende gefunden wird.
func find_end_position() -> Vector2i:
	for i in range(tiles.size()):
		if tiles[i] != null and tiles[i].type == TileType.Type.END:
			return index_to_position(i)

	return Vector2i(-1, -1)


## Erstellt eine tiefe Kopie dieses Grids.
func duplicate_grid() -> GridDefinition:
	var copy := GridDefinition.new(width, height)
	for i in range(tiles.size()):
		if tiles[i] != null:
			copy.tiles[i] = tiles[i].duplicate_tile()
	return copy


## Iteriert über alle Tiles und ruft den Callback mit (position, tile) auf.
func for_each_tile(callback: Callable) -> void:
	for i in range(tiles.size()):
		var position := index_to_position(i)
		callback.call(position, tiles[i])


## Gibt die Gesamtanzahl der Tiles im Grid zurück.
func get_tile_count() -> int:
	return width * height


## Zählt die Anzahl der nicht-null Tiles.
func count_filled_tiles() -> int:
	var count := 0
	for tile in tiles:
		if tile != null:
			count += 1
	return count
