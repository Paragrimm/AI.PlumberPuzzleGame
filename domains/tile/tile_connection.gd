class_name TileConnection
## Verwaltet die Verbindungslogik für Tiles.
## Bestimmt welche Seiten eines Tiles basierend auf Typ und Rotation verbunden sind.

## Die vier Seiten eines Tiles, repräsentiert als Grad-Werte.
## Dies ermöglicht einfache Rotation durch Addition.
## Verwende TileConnection.Side.TOP etc. von außen.
enum Side {
	TOP = 0,
	RIGHT = 90,
	BOTTOM = 180,
	LEFT = 270,
}


## Gibt die Basis-Verbindungen für einen Tile-Typ bei Rotation 0° zurück.
static func _get_base_connections_for_type(tile_type: TileType.Type) -> Array:
	match tile_type:
		TileType.Type.STRAIGHT:
			return [Side.TOP, Side.BOTTOM]
		TileType.Type.CORNER:
			return [Side.TOP, Side.RIGHT]
		TileType.Type.START:
			return [Side.TOP]
		TileType.Type.END:
			return [Side.TOP]
		_:
			return []


## Gibt die verbundenen Seiten für ein Tile zurück.
## Berücksichtigt die aktuelle Rotation des Tiles.
## Rückgabe: Array von Side-Werten (int).
static func get_connected_sides(tile: TileDefinition) -> Array:
	if tile == null:
		return []

	var base_sides := _get_base_connections_for_type(tile.type)
	var rotated_sides: Array = []

	for base_side in base_sides:
		var rotated_value: int = (int(base_side) + tile.rotation_degrees) % 360
		rotated_sides.append(rotated_value)

	return rotated_sides


## Prüft, ob ein Tile eine Verbindung an einer bestimmten Seite hat.
## side: Ein TileConnection.Side Wert (int)
static func has_connection_at_side(tile: TileDefinition, side: int) -> bool:
	if tile == null:
		return false

	var connected_sides := get_connected_sides(tile)
	return side in connected_sides


## Gibt die gegenüberliegende Seite zurück.
## TOP <-> BOTTOM, LEFT <-> RIGHT
## side: Ein TileConnection.Side Wert (int)
static func get_opposite_side(side: int) -> int:
	return (side + 180) % 360


## Konvertiert einen Side-Wert in einen lesbaren String.
static func side_to_string(side: int) -> String:
	match side:
		Side.TOP:
			return "TOP"
		Side.RIGHT:
			return "RIGHT"
		Side.BOTTOM:
			return "BOTTOM"
		Side.LEFT:
			return "LEFT"
		_:
			return "UNKNOWN"


## Konvertiert einen String in einen Side-Wert.
## Gibt -1 zurück bei ungültigem String.
static func string_to_side(side_string: String) -> int:
	match side_string.to_upper():
		"TOP":
			return Side.TOP
		"RIGHT":
			return Side.RIGHT
		"BOTTOM":
			return Side.BOTTOM
		"LEFT":
			return Side.LEFT
		_:
			return -1


## Gibt alle vier Seiten als Array zurück.
static func get_all_sides() -> Array:
	return [Side.TOP, Side.RIGHT, Side.BOTTOM, Side.LEFT]


## Prüft ob zwei Seiten benachbart sind (nicht gegenüberliegend).
static func are_sides_adjacent(side_a: int, side_b: int) -> bool:
	var difference := absi(side_a - side_b)
	# Benachbarte Seiten haben eine Differenz von 90° oder 270° (wegen Wrap-around)
	return difference == 90 or difference == 270
