class_name TileDefinition
extends Resource
## Repräsentiert die Daten eines einzelnen Tiles im Puzzle.
## Speichert Typ und aktuelle Rotation.

## Der Typ des Tiles (STRAIGHT, CORNER, START, END).
@export var type: TileType.Type = TileType.Type.STRAIGHT

## Die aktuelle Rotation in Grad (0, 90, 180, 270).
@export var rotation_degrees: int = 0


func _init(initial_type: TileType.Type = TileType.Type.STRAIGHT, initial_rotation: int = 0) -> void:
	type = initial_type
	rotation_degrees = _normalize_rotation(initial_rotation)


## Dreht das Tile um 90° im Uhrzeigersinn.
## Hat keine Wirkung bei nicht drehbaren Tiles (START, END).
func rotate_clockwise() -> void:
	if not TileType.is_rotatable(type):
		return

	rotation_degrees = _normalize_rotation(rotation_degrees + 90)


## Dreht das Tile um 90° gegen den Uhrzeigersinn.
## Hat keine Wirkung bei nicht drehbaren Tiles (START, END).
func rotate_counter_clockwise() -> void:
	if not TileType.is_rotatable(type):
		return

	rotation_degrees = _normalize_rotation(rotation_degrees - 90)


## Setzt die Rotation auf einen bestimmten Wert.
func set_rotation(new_rotation: int) -> void:
	rotation_degrees = _normalize_rotation(new_rotation)


## Normalisiert die Rotation auf gültige Werte basierend auf dem Tile-Typ.
func _normalize_rotation(rotation: int) -> int:
	# Erst auf 0-359 normalisieren
	var normalized := rotation % 360
	if normalized < 0:
		normalized += 360

	# STRAIGHT hat nur 0° und 90° als sinnvolle Rotationen
	if type == TileType.Type.STRAIGHT:
		normalized = normalized % 180

	return normalized


## Erstellt eine tiefe Kopie dieses Tiles.
func duplicate_tile() -> TileDefinition:
	return TileDefinition.new(type, rotation_degrees)


## Serialisiert das Tile zu einem String-Format (z.B. "corner_90").
func to_string_format() -> String:
	var type_name := TileType.type_to_string(type)
	return "%s_%d" % [type_name, rotation_degrees]


## Erstellt ein TileDefinition aus einem String-Format (z.B. "corner_90").
## Gibt null zurück bei ungültigem Format.
static func from_string_format(format_string: String) -> TileDefinition:
	var parts := format_string.split("_")
	if parts.size() != 2:
		push_error("Invalid tile format: %s (expected 'type_rotation')" % format_string)
		return null

	var type_name := parts[0]
	var rotation_string := parts[1]

	var tile_type = TileType.string_to_type(type_name)
	if tile_type == null:
		push_error("Unknown tile type: %s" % type_name)
		return null

	if not rotation_string.is_valid_int():
		push_error("Invalid rotation value: %s" % rotation_string)
		return null

	var rotation := rotation_string.to_int()

	return TileDefinition.new(tile_type, rotation)


## Gibt eine lesbare String-Repräsentation zurück.
func _to_string() -> String:
	return "TileDefinition(%s, %d°)" % [TileType.type_to_string(type), rotation_degrees]
