class_name TileView
extends Control
## Visuelle Repräsentation eines Tiles im UI.
## Verarbeitet Klick-Events und zeigt den Tile-Zustand an.

## Signal wird ausgelöst wenn das Tile angeklickt wird.
signal tile_clicked

## Die Tile-Definition die dieses View darstellt.
var tile_definition: TileDefinition:
	set = set_tile_definition

## Position dieses Tiles im Grid (für Identifikation).
var grid_position: Vector2i = Vector2i.ZERO

## Referenzen zu Child-Nodes.
@onready var _background: ColorRect = $Background
@onready var _pipe_container: Control = $PipeContainer
@onready var _pipe_straight: ColorRect = $PipeContainer/PipeStraight
@onready var _pipe_corner: Control = $PipeContainer/PipeCorner
@onready var _pipe_single: ColorRect = $PipeContainer/PipeSingle

## Farbe für die Rohr-Linien.
const PIPE_COLOR := Color("2d2d2d")

## Standard-Hintergrundfarbe.
const DEFAULT_BACKGROUND_COLOR := Color("e0e0e0")


## Gibt die Farbe für einen Tile-Typ zurück (Placeholder-Grafiken).
static func _get_color_for_type(tile_type: TileType.Type) -> Color:
	match tile_type:
		TileType.Type.STRAIGHT:
			return Color("4a90d9")  # Blau
		TileType.Type.CORNER:
			return Color("d9944a")  # Orange
		TileType.Type.START:
			return Color("4ad95a")  # Grün
		TileType.Type.END:
			return Color("d94a4a")  # Rot
		_:
			return DEFAULT_BACKGROUND_COLOR


func _ready() -> void:
	# Sicherstellen dass dieses Control Maus-Events empfängt
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_visual()


func set_tile_definition(value: TileDefinition) -> void:
	tile_definition = value
	if is_inside_tree():
		_update_visual()


## Aktualisiert die visuelle Darstellung basierend auf tile_definition.
func _update_visual() -> void:
	if tile_definition == null:
		_show_empty_tile()
		return

	# Hintergrundfarbe basierend auf Typ
	_background.color = _get_color_for_type(tile_definition.type)

	# Rohr-Darstellung aktualisieren
	_update_pipe_display()

	# Rotation anwenden
	_pipe_container.rotation_degrees = tile_definition.rotation_degrees


## Zeigt ein leeres Tile an.
func _show_empty_tile() -> void:
	_background.color = DEFAULT_BACKGROUND_COLOR
	_pipe_straight.visible = false
	_pipe_corner.visible = false
	_pipe_single.visible = false


## Aktualisiert welches Rohr-Element sichtbar ist.
func _update_pipe_display() -> void:
	_pipe_straight.visible = false
	_pipe_corner.visible = false
	_pipe_single.visible = false

	if tile_definition == null:
		return

	match tile_definition.type:
		TileType.Type.STRAIGHT:
			_pipe_straight.visible = true
		TileType.Type.CORNER:
			_pipe_corner.visible = true
		TileType.Type.START, TileType.Type.END:
			_pipe_single.visible = true


## Verarbeitet GUI-Eingaben für Klick-Erkennung.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			tile_clicked.emit()
			accept_event()


## Wird aufgerufen nachdem das Tile rotiert wurde.
## Aktualisiert die visuelle Darstellung.
func on_tile_rotated() -> void:
	_update_visual()


## Setzt die Hervorhebung des Tiles (z.B. für verbundene Tiles).
func set_highlighted(highlighted: bool) -> void:
	if highlighted:
		_background.modulate = Color(1.3, 1.3, 1.3)
	else:
		_background.modulate = Color.WHITE


## Markiert das Tile als Teil des Lösungspfads.
func set_on_solution_path(on_path: bool) -> void:
	if on_path:
		_background.modulate = Color(1.0, 1.0, 0.7)
	else:
		_background.modulate = Color.WHITE
