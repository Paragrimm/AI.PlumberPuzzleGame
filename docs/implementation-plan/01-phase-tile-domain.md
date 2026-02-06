# Phase 1: Tile-Domain

## Ziel
Grundlegende Tile-Datenstrukturen und UI-Komponente erstellen.

---

## Dateien

### 1.1 `domains/tile/tile_type.gd`

**Zweck:** Enum für Tile-Typen

```gdscript
class_name TileType


enum Type {
    STRAIGHT,  # Gerades Rohr (oben-unten oder links-rechts)
    CORNER,    # Eck-Rohr (verbindet zwei benachbarte Seiten)
    START,     # Startpunkt (eine Richtung, nicht drehbar)
    END,       # Endpunkt (eine Richtung, nicht drehbar)
}


## Gibt zurück, ob dieser Tile-Typ drehbar ist
static func is_rotatable(type: Type) -> bool:
    return type != Type.START and type != Type.END


## Gibt die gültigen Rotationen für einen Tile-Typ zurück
static func get_valid_rotations(type: Type) -> Array[int]:
    match type:
        Type.STRAIGHT:
            return [0, 90]
        Type.CORNER:
            return [0, 90, 180, 270]
        Type.START, Type.END:
            return [0, 90, 180, 270]  # Fix bei Erstellung, aber alle möglich
        _:
            return []
```

---

### 1.2 `domains/tile/tile_definition.gd`

**Zweck:** Custom Resource für Tile-Daten

```gdscript
class_name TileDefinition
extends Resource


## Der Typ des Tiles (STRAIGHT, CORNER, START, END)
@export var type: TileType.Type = TileType.Type.STRAIGHT

## Die aktuelle Rotation in Grad (0, 90, 180, 270)
@export var rotation_degrees: int = 0


func _init(initial_type: TileType.Type = TileType.Type.STRAIGHT, initial_rotation: int = 0) -> void:
    type = initial_type
    rotation_degrees = initial_rotation


## Dreht das Tile um 90° im Uhrzeigersinn (wenn drehbar)
func rotate_clockwise() -> void:
    if not TileType.is_rotatable(type):
        return
    
    rotation_degrees = (rotation_degrees + 90) % 360
    
    # STRAIGHT hat nur 0° und 90° als sinnvolle Rotationen
    if type == TileType.Type.STRAIGHT:
        rotation_degrees = rotation_degrees % 180


## Erstellt eine Kopie dieses Tiles
func duplicate_tile() -> TileDefinition:
    return TileDefinition.new(type, rotation_degrees)


## Serialisiert zu String-Format (z.B. "corner_90")
func to_string_format() -> String:
    var type_name := ""
    match type:
        TileType.Type.STRAIGHT:
            type_name = "straight"
        TileType.Type.CORNER:
            type_name = "corner"
        TileType.Type.START:
            type_name = "start"
        TileType.Type.END:
            type_name = "end"
    
    return "%s_%d" % [type_name, rotation_degrees]


## Erstellt TileDefinition aus String-Format
static func from_string_format(format: String) -> TileDefinition:
    var parts := format.split("_")
    if parts.size() != 2:
        push_error("Invalid tile format: %s" % format)
        return null
    
    var type_name := parts[0]
    var rotation := parts[1].to_int()
    
    var tile_type: TileType.Type
    match type_name:
        "straight":
            tile_type = TileType.Type.STRAIGHT
        "corner":
            tile_type = TileType.Type.CORNER
        "start":
            tile_type = TileType.Type.START
        "end":
            tile_type = TileType.Type.END
        _:
            push_error("Unknown tile type: %s" % type_name)
            return null
    
    return TileDefinition.new(tile_type, rotation)
```

---

### 1.3 `domains/tile/tile_connection.gd`

**Zweck:** Logik für Tile-Verbindungen

```gdscript
class_name TileConnection


## Seiten eines Tiles (als Grad-Werte für einfache Rotation)
enum Side {
    TOP = 0,
    RIGHT = 90,
    BOTTOM = 180,
    LEFT = 270,
}


## Basis-Verbindungen pro Tile-Typ (bei Rotation 0°)
const BASE_CONNECTIONS := {
    TileType.Type.STRAIGHT: [Side.TOP, Side.BOTTOM],
    TileType.Type.CORNER: [Side.TOP, Side.RIGHT],
    TileType.Type.START: [Side.TOP],  # Standard, wird bei Erstellung festgelegt
    TileType.Type.END: [Side.TOP],    # Standard, wird bei Erstellung festgelegt
}


## Gibt die verbundenen Seiten für ein Tile zurück (unter Berücksichtigung der Rotation)
static func get_connected_sides(tile: TileDefinition) -> Array[Side]:
    var base_sides: Array = BASE_CONNECTIONS.get(tile.type, [])
    var rotated_sides: Array[Side] = []
    
    for side in base_sides:
        var rotated_value := (side + tile.rotation_degrees) % 360
        rotated_sides.append(rotated_value as Side)
    
    return rotated_sides


## Prüft, ob ein Tile eine bestimmte Seite als Verbindung hat
static func has_connection_at_side(tile: TileDefinition, side: Side) -> bool:
    var connected_sides := get_connected_sides(tile)
    return side in connected_sides


## Gibt die gegenüberliegende Seite zurück
static func get_opposite_side(side: Side) -> Side:
    return ((side + 180) % 360) as Side
```

---

### 1.4 `domains/tile/tile_view.gd`

**Zweck:** UI-Script für Tile-Darstellung und Interaktion

```gdscript
class_name TileView
extends Control


## Signal wenn das Tile angeklickt wird
signal tile_clicked


## Die Tile-Definition, die dieses View darstellt
var tile_definition: TileDefinition:
    set = set_tile_definition


## Position im Grid (für Identifikation)
var grid_position: Vector2i = Vector2i.ZERO


@onready var _background: ColorRect = $Background
@onready var _connection_indicator: Control = $ConnectionIndicator


## Farben für verschiedene Tile-Typen (Placeholder)
const TYPE_COLORS := {
    TileType.Type.STRAIGHT: Color.CORNFLOWER_BLUE,
    TileType.Type.CORNER: Color.CORAL,
    TileType.Type.START: Color.LIME_GREEN,
    TileType.Type.END: Color.TOMATO,
}


func _ready() -> void:
    _update_visual()


func set_tile_definition(value: TileDefinition) -> void:
    tile_definition = value
    if is_inside_tree():
        _update_visual()


func _update_visual() -> void:
    if tile_definition == null:
        return
    
    # Hintergrundfarbe basierend auf Typ
    _background.color = TYPE_COLORS.get(tile_definition.type, Color.GRAY)
    
    # Rotation anwenden
    _connection_indicator.rotation_degrees = tile_definition.rotation_degrees


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
            tile_clicked.emit()
            accept_event()


## Wird aufgerufen wenn das Tile rotiert wurde
func on_tile_rotated() -> void:
    _update_visual()
```

---

### 1.5 `domains/tile/tile.tscn`

**Zweck:** Szene für Tile-UI (Placeholder-Grafik)

```
Struktur:
- Control (Root, script: tile_view.gd)
  - Background (ColorRect, anchors: full rect)
  - ConnectionIndicator (Control, anchors: full rect)
    - TopConnection (ColorRect, oben zentriert)
    - BottomConnection (ColorRect, unten zentriert)
    - (weitere je nach Bedarf)
```

**Szenen-Setup:**
- `custom_minimum_size`: 64x64
- `Background`: Füllt gesamte Fläche
- `ConnectionIndicator`: Container für Verbindungs-Visualisierung, wird rotiert

---

## Verifikation

### Tests nach Phase 1:

1. **TileDefinition erstellen und rotieren:**
```gdscript
var tile := TileDefinition.new(TileType.Type.CORNER, 0)
print(tile.to_string_format())  # "corner_0"
tile.rotate_clockwise()
print(tile.to_string_format())  # "corner_90"
```

2. **Verbindungen prüfen:**
```gdscript
var tile := TileDefinition.new(TileType.Type.CORNER, 90)
var sides := TileConnection.get_connected_sides(tile)
# Erwartung: [RIGHT, BOTTOM] (90° + 0° = RIGHT, 90° + 90° = BOTTOM)
```

3. **String-Roundtrip:**
```gdscript
var original := TileDefinition.new(TileType.Type.STRAIGHT, 90)
var format := original.to_string_format()
var restored := TileDefinition.from_string_format(format)
assert(restored.type == original.type)
assert(restored.rotation_degrees == original.rotation_degrees)
```

4. **Tile-Szene instanziieren und Klick testen:**
- Szene im Editor laden
- Verschiedene Tile-Typen zuweisen
- Klick-Signal prüfen

---

## Abhängigkeiten

- Keine externen Abhängigkeiten
- Basis für alle weiteren Phasen
