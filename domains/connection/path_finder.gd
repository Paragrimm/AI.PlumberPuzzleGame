class_name PathFinder
## Findet Pfade von Start zu Ende mittels BFS.


## Ergebnis einer Pfadsuche.
class PathResult:
	## Ob ein Pfad gefunden wurde.
	var found: bool = false

	## Der Pfad als Array von Positionen (inklusive Start und Ende).
	var path: Array[Vector2i] = []

	## Alle besuchten Positionen während der Suche.
	var visited: Array[Vector2i] = []


## Findet den kürzesten Pfad von Start zu Ende.
## Verwendet Breadth-First Search (BFS).
static func find_path(grid: GridDefinition) -> PathResult:
	var result := PathResult.new()

	var start_pos := grid.find_start_position()
	var end_pos := grid.find_end_position()

	# Prüfen ob Start und Ende existieren
	if start_pos == Vector2i(-1, -1) or end_pos == Vector2i(-1, -1):
		return result

	# BFS initialisieren
	var queue: Array[Vector2i] = [start_pos]
	var visited_dict: Dictionary = {start_pos: true}
	var came_from: Dictionary = {}  # Position -> vorherige Position

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		result.visited.append(current)

		# Ziel erreicht?
		if current == end_pos:
			result.found = true
			result.path = _reconstruct_path(came_from, start_pos, end_pos)
			return result

		# Verbundene Nachbarn besuchen
		var connected := ConnectionChecker.get_connected_neighbors(grid, current)
		for neighbor in connected:
			if neighbor not in visited_dict:
				visited_dict[neighbor] = true
				came_from[neighbor] = current
				queue.append(neighbor)

	# Kein Pfad gefunden
	return result


## Rekonstruiert den Pfad aus der came_from-Map.
static func _reconstruct_path(
	came_from: Dictionary, start: Vector2i, end: Vector2i
) -> Array[Vector2i]:
	var path: Array[Vector2i] = [end]
	var current := end

	while current != start:
		current = came_from[current]
		path.insert(0, current)

	return path


## Prüft ob das Puzzle gelöst ist (Start und Ende sind verbunden).
static func is_puzzle_solved(grid: GridDefinition) -> bool:
	var result := find_path(grid)
	return result.found


## Findet alle vom Start aus erreichbaren Positionen.
static func find_reachable_from_start(grid: GridDefinition) -> Array[Vector2i]:
	var start_pos := grid.find_start_position()
	if start_pos == Vector2i(-1, -1):
		return []

	return _flood_fill(grid, start_pos)


## Flood-Fill von einer Startposition aus.
static func _flood_fill(grid: GridDefinition, start: Vector2i) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var visited_dict: Dictionary = {start: true}

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		reachable.append(current)

		var connected := ConnectionChecker.get_connected_neighbors(grid, current)
		for neighbor in connected:
			if neighbor not in visited_dict:
				visited_dict[neighbor] = true
				queue.append(neighbor)

	return reachable
