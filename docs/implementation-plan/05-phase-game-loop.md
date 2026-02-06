# Phase 5: Game Loop

## Ziel
Spiellogik implementieren: Tile-Rotation bei Klick, Züge zählen, Win-Condition erkennen und Spielbildschirm aufbauen.

---

## Dateien

### 5.1 `game/game_manager.gd`

**Zweck:** Verwaltet Spielzustand, Züge und Statistiken

```gdscript
class_name GameManager
extends Node


## Signal wenn ein Zug gemacht wurde
signal move_made(move_count: int)

## Signal wenn sich die Anzahl Verbindungen geändert hat
signal connections_changed(connection_count: int)

## Signal wenn das Puzzle gelöst wurde
signal puzzle_solved

## Signal wenn das Puzzle zurückgesetzt wurde
signal puzzle_reset


## Das aktuelle Puzzle
var current_puzzle: PuzzleDefinition:
    set = set_current_puzzle

## Anzahl der Züge (Rotationen) im aktuellen Puzzle
var move_count: int = 0

## Anzahl der aktuellen Verbindungen (vom Start aus erreichbar)
var connection_count: int = 0

## Ob das Puzzle bereits gelöst wurde
var is_solved: bool = false


func set_current_puzzle(value: PuzzleDefinition) -> void:
    current_puzzle = value
    _reset_stats()
    _update_connection_count()


func _reset_stats() -> void:
    move_count = 0
    is_solved = false
    move_made.emit(move_count)


## Wird aufgerufen wenn ein Tile rotiert werden soll
func rotate_tile_at(position: Vector2i) -> void:
    if current_puzzle == null or is_solved:
        return
    
    var tile := current_puzzle.grid.get_tile_at(position)
    if tile == null:
        return
    
    if not TileType.is_rotatable(tile.type):
        return
    
    # Tile rotieren
    tile.rotate_clockwise()
    
    # Zug zählen
    move_count += 1
    move_made.emit(move_count)
    
    # Verbindungen aktualisieren
    _update_connection_count()
    
    # Win-Condition prüfen
    _check_win_condition()


func _update_connection_count() -> void:
    if current_puzzle == null:
        connection_count = 0
        connections_changed.emit(0)
        return
    
    connection_count = PuzzleSolver.count_connected_tiles(current_puzzle)
    connections_changed.emit(connection_count)


func _check_win_condition() -> void:
    if current_puzzle == null:
        return
    
    if current_puzzle.is_solved():
        is_solved = true
        puzzle_solved.emit()


## Setzt das aktuelle Puzzle zurück
func reset_puzzle() -> void:
    if current_puzzle == null:
        return
    
    current_puzzle.reset()
    _reset_stats()
    _update_connection_count()
    puzzle_reset.emit()


## Lädt ein neues Puzzle vom Generator
func load_new_puzzle(config: PuzzleGenerator.GeneratorConfig = null) -> void:
    var puzzle := PuzzleGenerator.generate(config)
    if puzzle != null:
        set_current_puzzle(puzzle)
```

---

### 5.2 `game/game_screen.gd`

**Zweck:** Hauptbildschirm-Script, verbindet UI-Komponenten

```gdscript
class_name GameScreen
extends Control


## Der Game Manager
@onready var _game_manager: GameManager = $GameManager

## Das Grid-View
@onready var _grid_view: GridView = $VBoxContainer/GridContainer/GridView

## Stats-Anzeige
@onready var _stats_display: StatsDisplay = $VBoxContainer/StatsDisplay

## Action-Buttons
@onready var _action_buttons: ActionButtons = $VBoxContainer/ActionButtons


func _ready() -> void:
    _connect_signals()
    _start_new_game()


func _connect_signals() -> void:
    # Grid-Klicks an GameManager weiterleiten
    _grid_view.tile_clicked.connect(_on_tile_clicked)
    
    # GameManager-Events
    _game_manager.move_made.connect(_on_move_made)
    _game_manager.connections_changed.connect(_on_connections_changed)
    _game_manager.puzzle_solved.connect(_on_puzzle_solved)
    _game_manager.puzzle_reset.connect(_on_puzzle_reset)
    
    # Button-Events
    _action_buttons.reset_pressed.connect(_on_reset_pressed)
    _action_buttons.next_puzzle_pressed.connect(_on_next_puzzle_pressed)


func _start_new_game() -> void:
    _game_manager.load_new_puzzle()
    _grid_view.grid_definition = _game_manager.current_puzzle.grid
    _action_buttons.show_next_button(false)


func _on_tile_clicked(position: Vector2i) -> void:
    _game_manager.rotate_tile_at(position)
    _grid_view.update_tile_at(position)


func _on_move_made(count: int) -> void:
    _stats_display.set_move_count(count)


func _on_connections_changed(count: int) -> void:
    _stats_display.set_connection_count(count)


func _on_puzzle_solved() -> void:
    _stats_display.show_solved_message()
    _action_buttons.show_next_button(true)


func _on_puzzle_reset() -> void:
    _grid_view.refresh_all_tiles()
    _stats_display.hide_solved_message()
    _action_buttons.show_next_button(false)


func _on_reset_pressed() -> void:
    _game_manager.reset_puzzle()


func _on_next_puzzle_pressed() -> void:
    _start_new_game()
```

---

### 5.3 `game/game_screen.tscn`

**Zweck:** Hauptbildschirm-Szene

```
Struktur:
- Control (Root, script: game_screen.gd, anchors: full rect)
  - GameManager (Node, script: game_manager.gd)
  - VBoxContainer (anchors: center, centered)
    - StatsDisplay (scene: ui/stats_display.tscn)
    - GridContainer (MarginContainer, für Abstand)
      - GridView (scene: domains/grid/grid.tscn)
    - ActionButtons (scene: ui/action_buttons.tscn)

Layout:
- VBoxContainer ist horizontal und vertikal zentriert
- StatsDisplay oben
- Grid in der Mitte
- Buttons unten
```

---

### 5.4 `ui/stats_display.gd`

**Zweck:** Zeigt Spielstatistiken an

```gdscript
class_name StatsDisplay
extends HBoxContainer


@onready var _move_count_label: Label = $MoveCountLabel
@onready var _connection_count_label: Label = $ConnectionCountLabel
@onready var _solved_label: Label = $SolvedLabel


func _ready() -> void:
    _solved_label.visible = false
    set_move_count(0)
    set_connection_count(0)


func set_move_count(count: int) -> void:
    _move_count_label.text = "Züge: %d" % count


func set_connection_count(count: int) -> void:
    _connection_count_label.text = "Verbindungen: %d" % count


func show_solved_message() -> void:
    _solved_label.visible = true
    _solved_label.text = "Gelöst!"


func hide_solved_message() -> void:
    _solved_label.visible = false
```

---

### 5.5 `ui/stats_display.tscn`

**Zweck:** Szene für Statistik-Anzeige

```
Struktur:
- HBoxContainer (Root, script: stats_display.gd)
  - MoveCountLabel (Label, text: "Züge: 0")
  - ConnectionCountLabel (Label, text: "Verbindungen: 0")
  - SolvedLabel (Label, text: "Gelöst!", visible: false, modulate: green)

Eigenschaften:
- theme_override_constants/separation: 20
- Labels haben minimum size für konsistentes Layout
```

---

### 5.6 `ui/action_buttons.gd`

**Zweck:** Verwaltet Aktions-Buttons

```gdscript
class_name ActionButtons
extends HBoxContainer


## Signal wenn Reset gedrückt wird
signal reset_pressed

## Signal wenn "Nächstes Puzzle" gedrückt wird
signal next_puzzle_pressed


@onready var _reset_button: Button = $ResetButton
@onready var _next_button: Button = $NextPuzzleButton


func _ready() -> void:
    _reset_button.pressed.connect(_on_reset_pressed)
    _next_button.pressed.connect(_on_next_pressed)
    _next_button.visible = false


func _on_reset_pressed() -> void:
    reset_pressed.emit()


func _on_next_pressed() -> void:
    next_puzzle_pressed.emit()


func show_next_button(visible: bool) -> void:
    _next_button.visible = visible
```

---

### 5.7 `ui/action_buttons.tscn`

**Zweck:** Szene für Aktions-Buttons

```
Struktur:
- HBoxContainer (Root, script: action_buttons.gd)
  - ResetButton (Button, text: "Reset")
  - NextPuzzleButton (Button, text: "Nächstes Puzzle", visible: false)

Eigenschaften:
- theme_override_constants/separation: 10
- Buttons haben custom_minimum_size für einheitliche Größe
```

---

### 5.8 `main.tscn`

**Zweck:** Einstiegspunkt der Anwendung

```
Struktur:
- Node (Root)
  - GameScreen (scene: game/game_screen.tscn)

project.godot Einstellungen:
- run/main_scene: "res://main.tscn"
```

---

## Verifikation

### Tests nach Phase 5:

1. **Spiel starten:**
- Szene main.tscn starten
- Grid sollte mit generiertem Puzzle erscheinen
- Stats zeigen "Züge: 0" und "Verbindungen: X"

2. **Tile rotieren:**
- Auf ein Tile klicken
- Tile sollte sich um 90° drehen
- Zähler erhöht sich auf "Züge: 1"
- Verbindungs-Zähler aktualisiert sich

3. **Start/Ende nicht drehbar:**
- Klick auf Start-Tile (grün) → keine Rotation
- Klick auf End-Tile (rot) → keine Rotation
- Zähler bleibt unverändert

4. **Puzzle lösen:**
- Alle Tiles so drehen, dass Start und Ende verbunden sind
- "Gelöst!" erscheint
- "Nächstes Puzzle" Button erscheint
- Weitere Klicks auf Tiles haben keine Wirkung

5. **Reset:**
- Reset-Button drücken
- Alle Tiles auf Ausgangszustand
- Zähler zurück auf 0
- "Gelöst!" verschwindet

6. **Nächstes Puzzle:**
- Nach Lösung "Nächstes Puzzle" drücken
- Neues Puzzle wird generiert
- Stats werden zurückgesetzt

---

## Abhängigkeiten

- Phase 1: Tile-Domain
- Phase 2: Grid-Domain
- Phase 3: Connection-Domain
- Phase 4: Puzzle-Domain (PuzzleGenerator, PuzzleSolver)
