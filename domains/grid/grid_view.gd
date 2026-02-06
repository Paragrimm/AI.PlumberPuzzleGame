class_name GridView
extends GridContainer
## Visuelle Repräsentation eines Grids.
## Verwaltet TileView-Instanzen und leitet Klick-Events weiter.

## Signal wenn ein Tile im Grid angeklickt wird.
signal tile_clicked(grid_pos: Vector2i)

## Signal wenn sich das Grid geändert hat.
signal grid_updated

## Die Grid-Definition die dieses View darstellt.
var grid_definition: GridDefinition:
	set = set_grid_definition

## Referenz zur Tile-Szene (wird im Editor gesetzt).
@export var tile_scene: PackedScene

## Cache für TileView-Instanzen: Vector2i -> TileView
var _tile_views: Dictionary = {}


func set_grid_definition(value: GridDefinition) -> void:
	grid_definition = value
	if is_inside_tree():
		_rebuild_grid()


func _ready() -> void:
	if grid_definition != null:
		_rebuild_grid()


## Baut das Grid komplett neu auf.
func _rebuild_grid() -> void:
	# Alte Tiles entfernen
	for child in get_children():
		child.queue_free()
	_tile_views.clear()

	if grid_definition == null:
		return

	# GridContainer konfigurieren
	columns = grid_definition.width

	# Tiles erstellen (row-major order)
	for y in range(grid_definition.height):
		for x in range(grid_definition.width):
			var pos := Vector2i(x, y)
			var tile_view := _create_tile_view(pos)
			add_child(tile_view)
			_tile_views[pos] = tile_view


## Erstellt ein TileView für eine Position.
func _create_tile_view(pos: Vector2i) -> TileView:
	var tile_view: TileView

	if tile_scene != null:
		tile_view = tile_scene.instantiate() as TileView
	else:
		push_error("tile_scene is not set! Creating empty Control as placeholder.")
		tile_view = TileView.new()

	tile_view.grid_position = pos
	tile_view.tile_definition = grid_definition.get_tile_at(pos)
	tile_view.tile_clicked.connect(_on_tile_clicked.bind(pos))

	return tile_view


## Handler für Tile-Klicks.
func _on_tile_clicked(pos: Vector2i) -> void:
	tile_clicked.emit(pos)


## Aktualisiert die Anzeige eines einzelnen Tiles.
func update_tile_at(pos: Vector2i) -> void:
	if pos not in _tile_views:
		return

	var tile_view: TileView = _tile_views[pos]
	tile_view.tile_definition = grid_definition.get_tile_at(pos)
	tile_view.on_tile_rotated()


## Aktualisiert alle Tiles.
func refresh_all_tiles() -> void:
	for pos in _tile_views:
		update_tile_at(pos)
	grid_updated.emit()


## Gibt das TileView an einer Position zurück.
func get_tile_view_at(pos: Vector2i) -> TileView:
	return _tile_views.get(pos, null)


## Hebt bestimmte Tiles hervor.
func highlight_tiles(positions: Array) -> void:
	# Erst alle zurücksetzen
	for pos in _tile_views:
		var tile_view: TileView = _tile_views[pos]
		tile_view.set_highlighted(false)

	# Dann ausgewählte hervorheben
	for pos in positions:
		if pos in _tile_views:
			var tile_view: TileView = _tile_views[pos]
			tile_view.set_highlighted(true)


## Markiert Tiles als Teil des Lösungspfads.
func show_solution_path(path: Array) -> void:
	# Erst alle zurücksetzen
	for pos in _tile_views:
		var tile_view: TileView = _tile_views[pos]
		tile_view.set_on_solution_path(false)

	# Dann Pfad markieren
	for pos in path:
		if pos in _tile_views:
			var tile_view: TileView = _tile_views[pos]
			tile_view.set_on_solution_path(true)
