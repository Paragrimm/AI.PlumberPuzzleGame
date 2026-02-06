extends Control
## Test-Szene für Verifikation der Domains.

@onready var _grid_view: GridView = $GridView


func _ready() -> void:
	# Phase 1 Tests
	_test_tile_definition()
	_test_tile_connection()
	_test_string_roundtrip()
	print("=== Alle Phase 1 Tests bestanden! ===")

	# Phase 2 Tests
	_test_grid_definition()
	_test_grid_logic()
	_test_grid_view()
	print("=== Alle Phase 2 Tests bestanden! ===")

	# Phase 3 Tests
	_test_connection_checker()
	_test_path_finder()
	print("=== Alle Phase 3 Tests bestanden! ===")

	# Phase 4 Tests
	_test_puzzle_generator()
	_test_puzzle_json_roundtrip()
	_test_puzzle_difficulty()
	print("=== Alle Phase 4 Tests bestanden! ===")


func _test_tile_definition() -> void:
	print("--- Test: TileDefinition ---")

	# Test 1: Erstellen und Rotation
	var tile := TileDefinition.new(TileType.Type.CORNER, 0)
	print("Erstellt: %s" % tile.to_string_format())
	assert(tile.to_string_format() == "corner_0", "Fehler: Initiale Rotation")

	tile.rotate_clockwise()
	print("Nach Rotation: %s" % tile.to_string_format())
	assert(tile.to_string_format() == "corner_90", "Fehler: Rotation um 90°")

	# Test 2: STRAIGHT normalisiert zu 0/90
	var straight := TileDefinition.new(TileType.Type.STRAIGHT, 180)
	print("STRAIGHT mit 180°: %s" % straight.to_string_format())
	assert(straight.rotation_degrees == 0, "Fehler: STRAIGHT sollte 180° auf 0° normalisieren")

	# Test 3: START/END nicht drehbar
	var start := TileDefinition.new(TileType.Type.START, 90)
	start.rotate_clockwise()
	print("START nach Rotation: %s" % start.to_string_format())
	assert(start.rotation_degrees == 90, "Fehler: START sollte sich nicht drehen")

	print("TileDefinition Tests: OK")


func _test_tile_connection() -> void:
	print("--- Test: TileConnection ---")

	# Test 1: CORNER bei 0° hat TOP und RIGHT
	var corner := TileDefinition.new(TileType.Type.CORNER, 0)
	var sides := TileConnection.get_connected_sides(corner)
	print("CORNER 0° Seiten: %s" % str(sides))
	assert(TileConnection.Side.TOP in sides, "Fehler: CORNER 0° sollte TOP haben")
	assert(TileConnection.Side.RIGHT in sides, "Fehler: CORNER 0° sollte RIGHT haben")

	# Test 2: CORNER bei 90° hat RIGHT und BOTTOM
	corner.rotate_clockwise()
	sides = TileConnection.get_connected_sides(corner)
	print("CORNER 90° Seiten: %s" % str(sides))
	assert(TileConnection.Side.RIGHT in sides, "Fehler: CORNER 90° sollte RIGHT haben")
	assert(TileConnection.Side.BOTTOM in sides, "Fehler: CORNER 90° sollte BOTTOM haben")

	# Test 3: Gegenüberliegende Seiten
	var opposite := TileConnection.get_opposite_side(TileConnection.Side.TOP)
	print("Gegenüber von TOP: %s" % TileConnection.side_to_string(opposite))
	assert(opposite == TileConnection.Side.BOTTOM, "Fehler: Gegenüber von TOP sollte BOTTOM sein")

	# Test 4: STRAIGHT bei 0° hat TOP und BOTTOM
	var straight := TileDefinition.new(TileType.Type.STRAIGHT, 0)
	sides = TileConnection.get_connected_sides(straight)
	print("STRAIGHT 0° Seiten: %s" % str(sides))
	assert(TileConnection.Side.TOP in sides, "Fehler: STRAIGHT 0° sollte TOP haben")
	assert(TileConnection.Side.BOTTOM in sides, "Fehler: STRAIGHT 0° sollte BOTTOM haben")

	# Test 5: STRAIGHT bei 90° hat LEFT und RIGHT
	straight.rotate_clockwise()
	sides = TileConnection.get_connected_sides(straight)
	print("STRAIGHT 90° Seiten: %s" % str(sides))
	assert(TileConnection.Side.LEFT in sides, "Fehler: STRAIGHT 90° sollte LEFT haben")
	assert(TileConnection.Side.RIGHT in sides, "Fehler: STRAIGHT 90° sollte RIGHT haben")

	print("TileConnection Tests: OK")


func _test_string_roundtrip() -> void:
	print("--- Test: String Roundtrip ---")

	var test_cases := [
		["corner_0", TileType.Type.CORNER, 0],
		["corner_90", TileType.Type.CORNER, 90],
		["straight_0", TileType.Type.STRAIGHT, 0],
		["straight_90", TileType.Type.STRAIGHT, 90],
		["start_270", TileType.Type.START, 270],
		["end_180", TileType.Type.END, 180],
	]

	for test_case in test_cases:
		var format_string: String = test_case[0]
		var expected_type: TileType.Type = test_case[1]
		var expected_rotation: int = test_case[2]

		var tile := TileDefinition.from_string_format(format_string)
		assert(tile != null, "Fehler: Konnte '%s' nicht parsen" % format_string)
		assert(tile.type == expected_type, "Fehler: Typ stimmt nicht für '%s'" % format_string)
		assert(
			tile.rotation_degrees == expected_rotation,
			"Fehler: Rotation stimmt nicht für '%s'" % format_string
		)

		var roundtrip := tile.to_string_format()
		assert(
			roundtrip == format_string,
			"Fehler: Roundtrip fehlgeschlagen für '%s' -> '%s'" % [format_string, roundtrip]
		)
		print("Roundtrip OK: %s" % format_string)

	print("String Roundtrip Tests: OK")


func _test_grid_definition() -> void:
	print("--- Test: GridDefinition ---")

	# Test 1: Grid erstellen
	var grid := GridDefinition.new(4, 4)
	assert(grid.width == 4, "Fehler: Breite sollte 4 sein")
	assert(grid.height == 4, "Fehler: Höhe sollte 4 sein")
	assert(grid.get_tile_count() == 16, "Fehler: Tile-Anzahl sollte 16 sein")
	print("Grid erstellt: %dx%d" % [grid.width, grid.height])

	# Test 2: Tiles setzen und abrufen
	var tile := TileDefinition.new(TileType.Type.CORNER, 90)
	grid.set_tile_at(Vector2i(1, 1), tile)
	var retrieved := grid.get_tile_at(Vector2i(1, 1))
	assert(retrieved == tile, "Fehler: Tile wurde nicht korrekt gespeichert")
	print("Tile setzen/abrufen: OK")

	# Test 3: Ungültige Position
	var invalid := grid.get_tile_at(Vector2i(-1, 0))
	assert(invalid == null, "Fehler: Ungültige Position sollte null zurückgeben")
	invalid = grid.get_tile_at(Vector2i(5, 5))
	assert(invalid == null, "Fehler: Position außerhalb sollte null zurückgeben")
	print("Ungültige Positionen: OK")

	# Test 4: Nachbarn
	var neighbors := grid.get_neighbor_positions(Vector2i(0, 0))
	assert(neighbors.size() == 2, "Fehler: Ecke sollte 2 Nachbarn haben")
	print("Nachbarn Ecke (0,0): %s" % str(neighbors))

	neighbors = grid.get_neighbor_positions(Vector2i(1, 1))
	assert(neighbors.size() == 4, "Fehler: Mitte sollte 4 Nachbarn haben")
	print("Nachbarn Mitte (1,1): %s" % str(neighbors))

	# Test 5: Start/Ende finden
	grid.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.START, 90))
	grid.set_tile_at(Vector2i(3, 3), TileDefinition.new(TileType.Type.END, 270))

	var start_pos := grid.find_start_position()
	var end_pos := grid.find_end_position()
	assert(start_pos == Vector2i(0, 0), "Fehler: Start-Position sollte (0,0) sein")
	assert(end_pos == Vector2i(3, 3), "Fehler: End-Position sollte (3,3) sein")
	print("Start/Ende gefunden: Start=%s, Ende=%s" % [start_pos, end_pos])

	# Test 6: Grid duplizieren
	var copy := grid.duplicate_grid()
	assert(copy.width == grid.width, "Fehler: Kopie Breite stimmt nicht")
	assert(copy.height == grid.height, "Fehler: Kopie Höhe stimmt nicht")
	assert(
		copy.get_tile_at(Vector2i(1, 1)).type == TileType.Type.CORNER,
		"Fehler: Kopie Tile stimmt nicht"
	)
	print("Grid duplizieren: OK")

	print("GridDefinition Tests: OK")


func _test_grid_logic() -> void:
	print("--- Test: GridLogic ---")

	# Test 1: Richtung zwischen Nachbarn
	var direction := GridLogic.get_direction_between(Vector2i(1, 1), Vector2i(2, 1))
	assert(direction == TileConnection.Side.RIGHT, "Fehler: Richtung sollte RIGHT sein")
	print("Richtung (1,1) -> (2,1): %s" % TileConnection.side_to_string(direction))

	direction = GridLogic.get_direction_between(Vector2i(1, 1), Vector2i(1, 0))
	assert(direction == TileConnection.Side.TOP, "Fehler: Richtung sollte TOP sein")
	print("Richtung (1,1) -> (1,0): %s" % TileConnection.side_to_string(direction))

	# Test 2: Nachbar in Richtung
	var neighbor := GridLogic.get_neighbor_in_direction(Vector2i(1, 1), TileConnection.Side.BOTTOM)
	assert(neighbor == Vector2i(1, 2), "Fehler: Nachbar sollte (1,2) sein")
	print("Nachbar von (1,1) nach BOTTOM: %s" % neighbor)

	# Test 3: Nachbarn prüfen
	assert(GridLogic.are_neighbors(Vector2i(1, 1), Vector2i(2, 1)), "Fehler: Sollten Nachbarn sein")
	assert(
		not GridLogic.are_neighbors(Vector2i(1, 1), Vector2i(3, 1)),
		"Fehler: Sollten keine Nachbarn sein"
	)
	print("Nachbar-Prüfung: OK")

	# Test 4: Manhattan-Distanz
	var distance := GridLogic.manhattan_distance(Vector2i(0, 0), Vector2i(3, 3))
	assert(distance == 6, "Fehler: Manhattan-Distanz sollte 6 sein")
	print("Manhattan-Distanz (0,0) -> (3,3): %d" % distance)

	print("GridLogic Tests: OK")


func _test_grid_view() -> void:
	print("--- Test: GridView ---")

	# Erstelle ein Test-Grid
	var grid := GridDefinition.new(3, 3)
	grid.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.START, 90))
	grid.set_tile_at(Vector2i(1, 0), TileDefinition.new(TileType.Type.STRAIGHT, 90))
	grid.set_tile_at(Vector2i(2, 0), TileDefinition.new(TileType.Type.CORNER, 180))
	grid.set_tile_at(Vector2i(2, 1), TileDefinition.new(TileType.Type.STRAIGHT, 0))
	grid.set_tile_at(Vector2i(2, 2), TileDefinition.new(TileType.Type.END, 0))

	# Weise das Grid dem GridView zu
	_grid_view.grid_definition = grid

	print("Grid visuell erstellt - prüfe die Anzeige!")
	print("GridView Tests: OK (visuelle Prüfung erforderlich)")


func _test_connection_checker() -> void:
	print("--- Test: ConnectionChecker ---")

	# Test 1: Zwei horizontal verbundene STRAIGHT Tiles
	var grid := GridDefinition.new(2, 1)
	var tile_left := TileDefinition.new(TileType.Type.STRAIGHT, 90)  # links-rechts
	var tile_right := TileDefinition.new(TileType.Type.STRAIGHT, 90)  # links-rechts
	grid.set_tile_at(Vector2i(0, 0), tile_left)
	grid.set_tile_at(Vector2i(1, 0), tile_right)

	var connected := ConnectionChecker.are_tiles_connected(grid, Vector2i(0, 0), Vector2i(1, 0))
	assert(connected == true, "Fehler: Horizontal verbundene STRAIGHT sollten verbunden sein")
	print("Horizontale STRAIGHT Verbindung: OK")

	# Test 2: Nicht verbunden bei falscher Rotation
	tile_right.rotation_degrees = 0  # oben-unten
	connected = ConnectionChecker.are_tiles_connected(grid, Vector2i(0, 0), Vector2i(1, 0))
	assert(connected == false, "Fehler: Nicht passende Rotation sollte nicht verbunden sein")
	print("Nicht verbundene Rotation: OK")

	# Test 3: CORNER zu STRAIGHT Verbindung
	var grid2 := GridDefinition.new(2, 2)
	grid2.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.CORNER, 90))  # RIGHT + BOTTOM
	grid2.set_tile_at(Vector2i(1, 0), TileDefinition.new(TileType.Type.STRAIGHT, 90))  # LEFT + RIGHT
	grid2.set_tile_at(Vector2i(0, 1), TileDefinition.new(TileType.Type.STRAIGHT, 0))  # TOP + BOTTOM

	connected = ConnectionChecker.are_tiles_connected(grid2, Vector2i(0, 0), Vector2i(1, 0))
	assert(connected == true, "Fehler: CORNER RIGHT sollte mit STRAIGHT LEFT verbunden sein")
	print("CORNER zu STRAIGHT horizontal: OK")

	connected = ConnectionChecker.are_tiles_connected(grid2, Vector2i(0, 0), Vector2i(0, 1))
	assert(connected == true, "Fehler: CORNER BOTTOM sollte mit STRAIGHT TOP verbunden sein")
	print("CORNER zu STRAIGHT vertikal: OK")

	# Test 4: get_connected_neighbors
	var neighbors := ConnectionChecker.get_connected_neighbors(grid2, Vector2i(0, 0))
	assert(neighbors.size() == 2, "Fehler: CORNER sollte 2 verbundene Nachbarn haben")
	print("Verbundene Nachbarn: %s" % str(neighbors))

	# Test 5: count_connections
	var count := ConnectionChecker.count_connections(grid2, Vector2i(0, 0))
	assert(count == 2, "Fehler: CORNER sollte 2 Verbindungen haben")
	print("Verbindungsanzahl: %d" % count)

	print("ConnectionChecker Tests: OK")


func _test_path_finder() -> void:
	print("--- Test: PathFinder ---")

	# Test 1: Einfacher horizontaler Pfad: START -> STRAIGHT -> END
	var grid := GridDefinition.new(3, 1)
	grid.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.START, 90))  # RIGHT
	grid.set_tile_at(Vector2i(1, 0), TileDefinition.new(TileType.Type.STRAIGHT, 90))  # LEFT-RIGHT
	grid.set_tile_at(Vector2i(2, 0), TileDefinition.new(TileType.Type.END, 270))  # LEFT

	var result := PathFinder.find_path(grid)
	assert(result.found == true, "Fehler: Pfad sollte gefunden werden")
	assert(result.path.size() == 3, "Fehler: Pfad sollte 3 Elemente haben")
	print("Einfacher Pfad gefunden: %s" % str(result.path))

	# Test 2: Kein Pfad bei falscher Rotation
	var grid2 := GridDefinition.new(3, 1)
	grid2.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.START, 90))  # RIGHT
	grid2.set_tile_at(Vector2i(1, 0), TileDefinition.new(TileType.Type.STRAIGHT, 0))  # TOP-BOTTOM (falsch!)
	grid2.set_tile_at(Vector2i(2, 0), TileDefinition.new(TileType.Type.END, 270))  # LEFT

	result = PathFinder.find_path(grid2)
	assert(result.found == false, "Fehler: Kein Pfad sollte gefunden werden")
	print("Kein Pfad bei falscher Rotation: OK")

	# Test 3: L-förmiger Pfad mit CORNER
	var grid3 := GridDefinition.new(2, 2)
	grid3.set_tile_at(Vector2i(0, 0), TileDefinition.new(TileType.Type.START, 90))  # RIGHT
	grid3.set_tile_at(Vector2i(1, 0), TileDefinition.new(TileType.Type.CORNER, 180))  # LEFT + BOTTOM
	grid3.set_tile_at(Vector2i(1, 1), TileDefinition.new(TileType.Type.END, 0))  # TOP

	result = PathFinder.find_path(grid3)
	assert(result.found == true, "Fehler: L-Pfad sollte gefunden werden")
	assert(result.path.size() == 3, "Fehler: L-Pfad sollte 3 Elemente haben")
	print("L-förmiger Pfad gefunden: %s" % str(result.path))

	# Test 4: is_puzzle_solved
	var solved := PathFinder.is_puzzle_solved(grid3)
	assert(solved == true, "Fehler: Puzzle sollte als gelöst erkannt werden")
	print("is_puzzle_solved: OK")

	# Test 5: find_reachable_from_start
	var reachable := PathFinder.find_reachable_from_start(grid3)
	assert(reachable.size() == 3, "Fehler: Alle 3 Tiles sollten erreichbar sein")
	print("Erreichbare Tiles: %s" % str(reachable))

	print("PathFinder Tests: OK")


func _test_puzzle_generator() -> void:
	print("--- Test: PuzzleGenerator ---")

	# Test 1: Puzzle generieren
	var config := PuzzleGenerator.GeneratorConfig.new()
	config.grid_width = 4
	config.grid_height = 4

	var puzzle := PuzzleGenerator.generate(config)
	assert(puzzle != null, "Fehler: Puzzle sollte generiert werden")
	assert(puzzle.grid != null, "Fehler: Puzzle sollte ein Grid haben")
	assert(puzzle.id != "", "Fehler: Puzzle sollte eine ID haben")
	print("Puzzle generiert: %s (%dx%d)" % [puzzle.id, puzzle.grid.width, puzzle.grid.height])

	# Test 2: Puzzle validieren
	var is_valid := PuzzleValidator.is_valid(puzzle)
	assert(is_valid == true, "Fehler: Generiertes Puzzle sollte gültig sein")
	print("Puzzle validiert: OK")

	# Test 3: Mehrere Puzzles generieren (Stress-Test)
	var success_count := 0
	for i in range(20):
		var test_puzzle := PuzzleGenerator.generate(config)
		if test_puzzle != null and PuzzleValidator.is_valid(test_puzzle):
			success_count += 1
	assert(success_count == 20, "Fehler: Alle 20 Puzzles sollten gültig sein")
	print("Generator Stress-Test: %d/20 erfolgreich" % success_count)

	# Test 4: Puzzle im GridView anzeigen
	_grid_view.grid_definition = puzzle.grid
	print("Generiertes Puzzle visuell angezeigt")

	print("PuzzleGenerator Tests: OK")


func _test_puzzle_json_roundtrip() -> void:
	print("--- Test: Puzzle JSON Roundtrip ---")

	# Puzzle generieren
	var config := PuzzleGenerator.GeneratorConfig.new()
	config.grid_width = 3
	config.grid_height = 3

	var puzzle := PuzzleGenerator.generate(config)
	assert(puzzle != null, "Fehler: Puzzle sollte generiert werden")

	# Zu JSON konvertieren
	var json := puzzle.to_json()
	assert(json.has("id"), "Fehler: JSON sollte 'id' haben")
	assert(json.has("grid_width"), "Fehler: JSON sollte 'grid_width' haben")
	assert(json.has("tiles"), "Fehler: JSON sollte 'tiles' haben")
	print("JSON erstellt: %d Tiles" % json.tiles.size())

	# Von JSON wiederherstellen
	var restored := PuzzleDefinition.from_json(json)
	assert(restored != null, "Fehler: Puzzle sollte wiederhergestellt werden")
	assert(restored.grid.width == puzzle.grid.width, "Fehler: Breite sollte übereinstimmen")
	assert(restored.grid.height == puzzle.grid.height, "Fehler: Höhe sollte übereinstimmen")
	assert(restored.id == puzzle.id, "Fehler: ID sollte übereinstimmen")
	print("Puzzle wiederhergestellt: OK")

	# Prüfen ob Tiles übereinstimmen
	var tiles_match := true
	for i in range(puzzle.grid.get_tile_count()):
		var pos := puzzle.grid.index_to_position(i)
		var orig_tile := puzzle.grid.get_tile_at(pos)
		var restored_tile := restored.grid.get_tile_at(pos)

		if orig_tile == null and restored_tile == null:
			continue
		if orig_tile == null or restored_tile == null:
			tiles_match = false
			break
		if orig_tile.to_string_format() != restored_tile.to_string_format():
			tiles_match = false
			break

	assert(tiles_match == true, "Fehler: Tiles sollten übereinstimmen")
	print("Tiles Roundtrip: OK")

	print("Puzzle JSON Roundtrip Tests: OK")


func _test_puzzle_difficulty() -> void:
	print("--- Test: PuzzleDifficulty ---")

	# Puzzle generieren
	var config := PuzzleGenerator.GeneratorConfig.new()
	config.grid_width = 4
	config.grid_height = 4

	var puzzle := PuzzleGenerator.generate(config)
	assert(puzzle != null, "Fehler: Puzzle sollte generiert werden")

	# Schwierigkeit berechnen
	var difficulty := puzzle.get_difficulty()
	var label := PuzzleDifficulty.get_difficulty_label(difficulty)
	print("Schwierigkeit: %.2f (%s)" % [difficulty, label])

	# Verschiedene Grid-Größen testen
	var sizes := [[3, 3], [4, 4], [5, 5]]
	for size_config in sizes:
		var test_config := PuzzleGenerator.GeneratorConfig.new()
		test_config.grid_width = size_config[0]
		test_config.grid_height = size_config[1]

		var test_puzzle := PuzzleGenerator.generate(test_config)
		if test_puzzle != null:
			var test_difficulty := test_puzzle.get_difficulty()
			var test_label := PuzzleDifficulty.get_difficulty_label(test_difficulty)
			print(
				(
					"Grid %dx%d: %.2f (%s)"
					% [size_config[0], size_config[1], test_difficulty, test_label]
				)
			)

	print("PuzzleDifficulty Tests: OK")
