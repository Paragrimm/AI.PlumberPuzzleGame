class_name TileType
## Definiert die verschiedenen Tile-Typen und deren Eigenschaften.

## Die verfügbaren Tile-Typen im Spiel.
enum Type {
	STRAIGHT,  ## Gerades Rohr (verbindet gegenüberliegende Seiten)
	CORNER,  ## Eck-Rohr (verbindet zwei benachbarte Seiten)
	START,  ## Startpunkt des Puzzles (eine Richtung, nicht drehbar)
	END,  ## Endpunkt des Puzzles (eine Richtung, nicht drehbar)
}


## Gibt zurück, ob dieser Tile-Typ vom Spieler gedreht werden kann.
static func is_rotatable(type: Type) -> bool:
	return type != Type.START and type != Type.END


## Gibt die gültigen Rotationen für einen Tile-Typ zurück (in Grad).
## STRAIGHT hat nur 0° und 90° (da 180° = 0° und 270° = 90°).
## CORNER hat alle vier Rotationen.
## START und END sind nicht drehbar, haben aber eine initiale Rotation.
static func get_valid_rotations(type: Type) -> Array[int]:
	match type:
		Type.STRAIGHT:
			return [0, 90]
		Type.CORNER:
			return [0, 90, 180, 270]
		Type.START, Type.END:
			return [0, 90, 180, 270]
		_:
			return []


## Gibt die Anzahl der Verbindungsseiten für einen Tile-Typ zurück.
static func get_connection_count(type: Type) -> int:
	match type:
		Type.STRAIGHT:
			return 2
		Type.CORNER:
			return 2
		Type.START, Type.END:
			return 1
		_:
			return 0


## Konvertiert einen Tile-Typ in einen String-Namen.
static func type_to_string(type: Type) -> String:
	match type:
		Type.STRAIGHT:
			return "straight"
		Type.CORNER:
			return "corner"
		Type.START:
			return "start"
		Type.END:
			return "end"
		_:
			return "unknown"


## Konvertiert einen String-Namen in einen Tile-Typ.
## Gibt null zurück wenn der String ungültig ist.
static func string_to_type(type_name: String) -> Variant:
	match type_name.to_lower():
		"straight":
			return Type.STRAIGHT
		"corner":
			return Type.CORNER
		"start":
			return Type.START
		"end":
			return Type.END
		_:
			return null
