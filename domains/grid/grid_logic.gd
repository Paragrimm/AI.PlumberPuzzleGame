class_name GridLogic
## Statische Hilfsklasse für Grid-Operationen.
## Stellt Funktionen für Nachbar-Ermittlung und Richtungsberechnung bereit.

## Mapping von Richtung (TileConnection.Side) zu Offset-Vektor.
const DIRECTION_OFFSETS := {
	TileConnection.Side.TOP: Vector2i(0, -1),
	TileConnection.Side.RIGHT: Vector2i(1, 0),
	TileConnection.Side.BOTTOM: Vector2i(0, 1),
	TileConnection.Side.LEFT: Vector2i(-1, 0),
}


## Gibt die Richtung von Position A zu Position B zurück.
## Die Positionen müssen benachbart sein.
static func get_direction_between(from_position: Vector2i, to_position: Vector2i) -> int:
	var offset := to_position - from_position

	if offset == Vector2i(0, -1):
		return TileConnection.Side.TOP
	elif offset == Vector2i(1, 0):
		return TileConnection.Side.RIGHT
	elif offset == Vector2i(0, 1):
		return TileConnection.Side.BOTTOM
	elif offset == Vector2i(-1, 0):
		return TileConnection.Side.LEFT

	push_error("Positions are not neighbors: %s -> %s" % [from_position, to_position])
	return TileConnection.Side.TOP


## Gibt die Nachbar-Position in einer bestimmten Richtung zurück.
static func get_neighbor_in_direction(position: Vector2i, direction: int) -> Vector2i:
	match direction:
		TileConnection.Side.TOP:
			return position + Vector2i(0, -1)
		TileConnection.Side.RIGHT:
			return position + Vector2i(1, 0)
		TileConnection.Side.BOTTOM:
			return position + Vector2i(0, 1)
		TileConnection.Side.LEFT:
			return position + Vector2i(-1, 0)
		_:
			push_error("Invalid direction: %d" % direction)
			return position


## Prüft ob zwei Positionen benachbart sind (horizontal oder vertikal).
static func are_neighbors(position_a: Vector2i, position_b: Vector2i) -> bool:
	var difference := position_b - position_a
	return (
		difference == Vector2i(0, -1)
		or difference == Vector2i(1, 0)
		or difference == Vector2i(0, 1)
		or difference == Vector2i(-1, 0)
	)


## Gibt alle vier Nachbar-Positionen zurück (auch ungültige).
## Rückgabe: Dictionary[int, Vector2i] - Direction -> Position
static func get_all_neighbor_positions(position: Vector2i) -> Dictionary:
	return {
		TileConnection.Side.TOP: position + Vector2i(0, -1),
		TileConnection.Side.RIGHT: position + Vector2i(1, 0),
		TileConnection.Side.BOTTOM: position + Vector2i(0, 1),
		TileConnection.Side.LEFT: position + Vector2i(-1, 0),
	}


## Berechnet die Manhattan-Distanz zwischen zwei Positionen.
static func manhattan_distance(position_a: Vector2i, position_b: Vector2i) -> int:
	return absi(position_a.x - position_b.x) + absi(position_a.y - position_b.y)
