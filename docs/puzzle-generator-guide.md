# Puzzle Generator - Dokumentation

## Übersicht

Der `PuzzleGenerator` erzeugt algorithmisch lösbare Pipe-Puzzles. Jedes generierte Puzzle hat garantiert einen gültigen Pfad von Start zu Ende.

---

## Grundlegende Nutzung

### Standard-Puzzle (4x4)

```gdscript
# Einfachste Variante - verwendet Standardwerte
var puzzle := PuzzleGenerator.generate()
```

### Puzzle mit eigener Konfiguration

```gdscript
var config := PuzzleGenerator.GeneratorConfig.new()
config.grid_width = 6
config.grid_height = 6

var puzzle := PuzzleGenerator.generate(config)
```

---

## Konfigurationsparameter

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `grid_width` | int | 4 | Breite des Puzzles in Tiles |
| `grid_height` | int | 4 | Höhe des Puzzles in Tiles |
| `start_position` | Vector2i | (-1, -1) | Feste Start-Position. (-1, -1) = zufällig |
| `end_position` | Vector2i | (-1, -1) | Feste End-Position. (-1, -1) = zufällig |
| `min_path_length` | int | 4 | Mindestlänge des Lösungspfads |
| `max_generation_attempts` | int | 100 | Maximale Versuche bis Fehler |
| `min_start_end_distance` | int | 3 | Mindest-Manhattan-Abstand zwischen Start und Ende |

### Beispiele

#### Großes 8x8 Puzzle

```gdscript
var config := PuzzleGenerator.GeneratorConfig.new()
config.grid_width = 8
config.grid_height = 8
config.min_path_length = 10  # Längerer Mindestpfad für größere Puzzles

var puzzle := PuzzleGenerator.generate(config)
```

#### Puzzle mit fester Start-Position

```gdscript
var config := PuzzleGenerator.GeneratorConfig.new()
config.start_position = Vector2i(0, 0)  # Start immer oben links

var puzzle := PuzzleGenerator.generate(config)
```

#### Schmales Puzzle (6x3)

```gdscript
var config := PuzzleGenerator.GeneratorConfig.new()
config.grid_width = 6
config.grid_height = 3
config.min_path_length = 6

var puzzle := PuzzleGenerator.generate(config)
```

---

## JSON-Export für Server/Datenbank

### Puzzle zu JSON konvertieren

```gdscript
var puzzle := PuzzleGenerator.generate()
var json_data: Dictionary = puzzle.to_json()

# Beispiel-Output:
# {
#   "id": "puzzle_1706889600",
#   "grid_width": 4,
#   "grid_height": 4,
#   "tiles": ["start_270", "corner_90", "straight_0", "end_180", ...]
# }
```

### JSON zu String (für HTTP/Speicherung)

```gdscript
var json_string := JSON.stringify(json_data)
# Kann nun an Server gesendet oder in Datei gespeichert werden
```

### Puzzle von JSON laden

```gdscript
# Von Dictionary
var puzzle := PuzzleDefinition.from_json(json_data)

# Von String
var parsed: Dictionary = JSON.parse_string(json_string)
var puzzle := PuzzleDefinition.from_json(parsed)
```

### JSON-Struktur

```json
{
  "id": "puzzle_1706889600",
  "grid_width": 4,
  "grid_height": 4,
  "tiles": [
    "corner_90",
    "straight_0",
    "corner_180",
    "start_270",
    "straight_90",
    "corner_0",
    "straight_0",
    "corner_270",
    "end_90",
    "straight_90",
    "corner_90",
    "straight_0",
    "corner_0",
    "straight_0",
    "straight_90",
    "corner_270"
  ]
}
```

**Tile-Format:** `{type}_{rotation}`
- Types: `straight`, `corner`, `start`, `end`
- Rotation: `0`, `90`, `180`, `270`

---

## Server-Hosting: Architektur-Empfehlung

### Option A: Pre-Generated Puzzles (Empfohlen)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Generator     │────▶│    Datenbank    │◀────│   Godot Client  │
│   (Offline)     │     │   (PostgreSQL)  │     │   (Spiel)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. **Generator-Script** (z.B. Python oder GDScript CLI):
   - Generiert Puzzles in Batches
   - Berechnet Schwierigkeit
   - Speichert in Datenbank

2. **REST-API**:
   - `GET /puzzles?difficulty=easy&limit=10`
   - `GET /puzzles/{id}`
   - `POST /puzzles/{id}/solved` (Tracking)

3. **Client**:
   - Holt Puzzles via HTTP
   - Lädt mit `PuzzleDefinition.from_json()`

### Option B: On-Demand Generation (Einfacher Start)

```
┌─────────────────┐     ┌─────────────────┐
│   Godot Client  │────▶│   Server (API)  │
│   (Spiel)       │◀────│   + Generator   │
└─────────────────┘     └─────────────────┘
```

- Server generiert Puzzles auf Anfrage
- Einfacher, aber höhere Latenz

### Datenbank-Schema (Beispiel)

```sql
CREATE TABLE puzzles (
    id UUID PRIMARY KEY,
    grid_width INT NOT NULL,
    grid_height INT NOT NULL,
    tiles JSONB NOT NULL,
    difficulty FLOAT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_puzzles_difficulty ON puzzles(difficulty);
CREATE INDEX idx_puzzles_size ON puzzles(grid_width, grid_height);
```

### HTTP-Request im Client

```gdscript
func fetch_puzzle_from_server(puzzle_id: String) -> PuzzleDefinition:
    var http := HTTPRequest.new()
    add_child(http)
    
    http.request("https://api.example.com/puzzles/" + puzzle_id)
    var result = await http.request_completed
    
    var json := JSON.parse_string(result[3].get_string_from_utf8())
    http.queue_free()
    
    return PuzzleDefinition.from_json(json)
```

---

## Bekannte Einschränkungen

### 1. Keine Schwierigkeit im JSON

Die Schwierigkeit wird dynamisch berechnet und nicht gespeichert. Bei Server-Hosting sollte die Schwierigkeit beim Import berechnet und in der Datenbank gespeichert werden:

```gdscript
var puzzle := PuzzleGenerator.generate()
var difficulty := PuzzleDifficulty.calculate(puzzle)

# Für Datenbank:
var data := puzzle.to_json()
data["difficulty"] = difficulty
```

### 2. Keine Lösungs-Speicherung

Das JSON enthält nur den Initial-Zustand (verwürfelt), nicht die Lösung. Falls gewünscht, könnte ein `solution_tiles`-Array ergänzt werden.

### 3. Validierung beim Import

Beim Laden von externen JSONs sollte validiert werden:

```gdscript
var puzzle := PuzzleDefinition.from_json(data)
if not PuzzleValidator.is_valid(puzzle):
    push_error("Invalid puzzle data from server")
    return null
```

### 4. Keine leeren Tiles

Aktuell gibt es keine "leeren" Tiles (ohne Verbindungen). Alle Tiles haben mindestens zwei Anschlüsse. Dies vereinfacht den Generator, limitiert aber die Puzzle-Varianz.

### 5. Determinismus

Der Generator verwendet `randf()` und ist nicht seedable. Für reproduzierbare Puzzles müsste ein Seed-Parameter ergänzt werden:

```gdscript
# Potentielle Erweiterung:
config.seed = 12345
```

---

## Schwierigkeit anpassen

### Grid-Größe

| Größe | Schwierigkeit | Empfohlener `min_path_length` |
|-------|---------------|-------------------------------|
| 3x3 | Sehr leicht | 3 |
| 4x4 | Leicht | 4 |
| 5x5 | Mittel | 6 |
| 6x6 | Schwer | 8 |
| 8x8 | Sehr schwer | 12 |

### Weitere Faktoren

- Mehr Ecken (CORNER) = schwerer (mehr Rotationen nötig)
- Längere Pfade = schwerer (mehr Tiles zum Ausrichten)
- Weit entfernte Start/Ende = oft längere Pfade

---

## Integration in GameManager

Der aktuelle `GameManager` nutzt den Generator bereits:

```gdscript
# game/game_manager.gd
func _generate_new_puzzle() -> void:
    var config := PuzzleGenerator.GeneratorConfig.new()
    config.grid_width = 4  # Hier anpassen
    config.grid_height = 4
    
    current_puzzle = PuzzleGenerator.generate(config)
```

Um die Grid-Größe zur Laufzeit änderbar zu machen, könnte ein Einstellungs-Menü ergänzt werden, das diese Werte modifiziert.
