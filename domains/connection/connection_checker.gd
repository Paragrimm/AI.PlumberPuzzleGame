class_name ConnectionChecker
## Prüft Verbindungen zwischen benachbarten Tiles im Grid.


## Prüft ob zwei benachbarte Tiles miteinander verbunden sind.
## Gibt true zurück wenn beide Tiles eine Verbindung zur jeweils anderen Seite haben.
static func are_tiles_connected(grid: GridDefinition, pos_a: Vector2i, pos_b: Vector2i) -> bool:
	# Prüfen ob Positionen gültig sind
	if not grid.is_valid_position(pos_a) or not grid.is_valid_position(pos_b):
		return false

	# Prüfen ob Positionen benachbart sind
	if not GridLogic.are_neighbors(pos_a, pos_b):
		return false

	var tile_a := grid.get_tile_at(pos_a)
	var tile_b := grid.get_tile_at(pos_b)

	# Null-Tiles haben keine Verbindung
	if tile_a == null or tile_b == null:
		return false

	# Richtung von A nach B ermitteln
	var direction_a_to_b := GridLogic.get_direction_between(pos_a, pos_b)
	var direction_b_to_a := TileConnection.get_opposite_side(direction_a_to_b)

	# Prüfen ob beide Tiles die entsprechende Verbindung haben
	var a_connects := TileConnection.has_connection_at_side(tile_a, direction_a_to_b)
	var b_connects := TileConnection.has_connection_at_side(tile_b, direction_b_to_a)

	return a_connects and b_connects


## Gibt alle Positionen zurück, die mit einer gegebenen Position verbunden sind.
static func get_connected_neighbors(grid: GridDefinition, pos: Vector2i) -> Array[Vector2i]:
	var connected: Array[Vector2i] = []
	var neighbors := grid.get_neighbor_positions(pos)

	for neighbor_pos in neighbors:
		if are_tiles_connected(grid, pos, neighbor_pos):
			connected.append(neighbor_pos)

	return connected


## Zählt die Anzahl der aktiven Verbindungen eines Tiles.
static func count_connections(grid: GridDefinition, pos: Vector2i) -> int:
	return get_connected_neighbors(grid, pos).size()


## Gibt alle Verbindungen im gesamten Grid zurück (als Array von Position-Paaren).
static func get_all_connections(grid: GridDefinition) -> Array:
	var connections: Array = []
	var checked_pairs: Dictionary = {}

	for i in range(grid.get_tile_count()):
		var pos := grid.index_to_position(i)
		var tile := grid.get_tile_at(pos)

		if tile == null:
			continue

		var neighbors := grid.get_neighbor_positions(pos)
		for neighbor_pos in neighbors:
			# Nur einmal pro Paar prüfen
			var pair_key := _make_pair_key(pos, neighbor_pos)
			if pair_key in checked_pairs:
				continue
			checked_pairs[pair_key] = true

			if are_tiles_connected(grid, pos, neighbor_pos):
				connections.append([pos, neighbor_pos])

	return connections


## Erstellt einen eindeutigen Key für ein Positionspaar.
static func _make_pair_key(pos_a: Vector2i, pos_b: Vector2i) -> String:
	# Sortieren damit (a,b) und (b,a) den gleichen Key haben
	if pos_a.x < pos_b.x or (pos_a.x == pos_b.x and pos_a.y < pos_b.y):
		return "%d,%d-%d,%d" % [pos_a.x, pos_a.y, pos_b.x, pos_b.y]
	else:
		return "%d,%d-%d,%d" % [pos_b.x, pos_b.y, pos_a.x, pos_a.y]
