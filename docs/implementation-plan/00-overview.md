# Pipe Puzzle Game - Implementierungsplan

## Projektübersicht
Ein Plumber/Pipe Puzzle Game für Godot 4.6 in GDScript mit:
- Algorithmischer Puzzle-Generierung
- Domain-Driven Design Struktur
- Custom Resources als Datenformat (mit JSON-Export für späteres Hosting)
- Variabler Grid-Größe

---

## Entscheidungen

| Thema | Entscheidung |
|-------|--------------|
| Puzzle-Erstellung | Algorithmische Generierung |
| Datenformat | Custom Resources, später `from_json`/`to_json` |
| Rotation-Format | Grad-Zahl (`straight_0`, `corner_90`) |
| Schwierigkeit | Dynamisch berechnet (nicht gespeichert) |
| Grid-Größe | Variabel, Generator-Parameter |
| UI | GridContainer mit austauschbarer Tile-Szene |
| Grafik | Placeholder (TextureRect, farbcodiert) |
| Architektur | Domain-Driven Design |
| Tile-Naming | `corner` (nicht `angular`) |
| Leere Tiles | Nein |

---

## Architektur (Domain-Driven Design)

```
res://
├── domains/
│   ├── tile/
│   │   ├── tile_definition.gd        # Resource: Tile-Daten
│   │   ├── tile_type.gd              # Enum: STRAIGHT, CORNER, START, END
│   │   ├── tile_connection.gd        # Logik: Welche Seiten sind verbunden
│   │   ├── tile_view.gd              # UI-Script für Tile
│   │   └── tile.tscn                 # Szene: Austauschbares Tile-UI
│   │
│   ├── grid/
│   │   ├── grid_definition.gd        # Resource: Grid-Daten (2D-Array von Tiles)
│   │   ├── grid_logic.gd             # Logik: Tile-Zugriff, Nachbar-Ermittlung
│   │   ├── grid_view.gd              # UI-Script für Grid
│   │   └── grid.tscn                 # Szene: GridContainer
│   │
│   ├── puzzle/
│   │   ├── puzzle_definition.gd      # Resource: Puzzle-Daten + from_json/to_json
│   │   ├── puzzle_generator.gd       # Algorithmus: Puzzle erzeugen
│   │   ├── puzzle_solver.gd          # Algorithmus: Lösung prüfen (BFS/DFS)
│   │   ├── puzzle_difficulty.gd      # Berechnung: Schwierigkeitsgrad
│   │   └── puzzle_validator.gd       # Prüft ob Puzzle lösbar ist
│   │
│   └── connection/
│       ├── connection_checker.gd     # Prüft Verbindung zwischen zwei Tiles
│       └── path_finder.gd            # Findet Pfad von Start zu Ende
│
├── game/
│   ├── game_manager.gd               # Spiel-Zustand, Züge, Stats
│   ├── game_screen.gd                # Hauptbildschirm-Script
│   ├── game_screen.tscn              # Hauptbildschirm-Szene
│   └── progress_tracker.gd           # Speichert gelöste Puzzles (Autoload)
│
├── ui/
│   ├── stats_display.gd              # Anzeige: Züge, Verbindungen
│   ├── stats_display.tscn
│   ├── action_buttons.gd             # Reset, Nächstes Puzzle
│   └── action_buttons.tscn
│
└── main.tscn                         # Einstiegspunkt
```

---

## Phasen-Übersicht

| Phase | Beschreibung | Dateien |
|-------|--------------|---------|
| 1 | Tile-Domain | [01-phase-tile-domain.md](01-phase-tile-domain.md) |
| 2 | Grid-Domain | [02-phase-grid-domain.md](02-phase-grid-domain.md) |
| 3 | Connection-Domain | [03-phase-connection-domain.md](03-phase-connection-domain.md) |
| 4 | Puzzle-Domain | [04-phase-puzzle-domain.md](04-phase-puzzle-domain.md) |
| 5 | Game Loop | [05-phase-game-loop.md](05-phase-game-loop.md) |
| 6 | Polish | [06-phase-polish.md](06-phase-polish.md) |

---

## Tile-System

### Tile-Typen und Rotationen

| Typ | Rotationen | Verbindungen bei 0° |
|-----|------------|---------------------|
| `STRAIGHT` | 0°, 90° | oben ↔ unten |
| `CORNER` | 0°, 90°, 180°, 270° | oben ↔ rechts |
| `START` | fix (nicht drehbar) | eine Richtung |
| `END` | fix (nicht drehbar) | eine Richtung |

### Verbindungslogik

Jedes Tile hat basierend auf Typ + Rotation eine Liste von verbundenen Seiten:
- Seiten: `TOP = 0`, `RIGHT = 90`, `BOTTOM = 180`, `LEFT = 270`
- Zwei Tiles sind verbunden, wenn Tile A Seite X hat und Tile B die gegenüberliegende Seite

---

## Schwierigkeitsberechnung

Dynamische Formel (nicht gespeichert):

```gdscript
func calculate_difficulty(puzzle: PuzzleDefinition) -> float:
    var base = puzzle.grid_width * puzzle.grid_height
    var rotations = _count_required_rotations(puzzle)
    var path_complexity = _calculate_path_complexity(puzzle)
    
    return (base * 0.3) + (rotations * 0.5) + (path_complexity * 0.2)
```

Faktoren:
- Grid-Größe (mehr Tiles = schwerer)
- Anzahl nötiger Rotationen zur Lösung
- Pfad-Komplexität (viele Kurven = schwerer)
