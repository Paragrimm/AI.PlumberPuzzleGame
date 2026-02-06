class_name GameScreen
extends Control
## Hauptbildschirm-Script, verbindet UI-Komponenten.

## Der Game Manager.
@onready var _game_manager: GameManager = $GameManager

## Das Grid-View.
@onready var _grid_view: GridView = $VBoxContainer/GridContainer/GridView

## Stats-Anzeige.
@onready var _stats_display: StatsDisplay = $VBoxContainer/StatsDisplay

## Action-Buttons.
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
	_stats_display.hide_solved_message()


func _on_tile_clicked(pos: Vector2i) -> void:
	_game_manager.rotate_tile_at(pos)
	_grid_view.update_tile_at(pos)


func _on_move_made(count: int) -> void:
	_stats_display.set_move_count(count)


func _on_connections_changed(count: int) -> void:
	_stats_display.set_connection_count(count)


func _on_puzzle_solved() -> void:
	_stats_display.show_solved_message()
	_action_buttons.show_next_button(true)
	# Zeige Lösungspfad
	var path := PuzzleSolver.get_solution_path(_game_manager.current_puzzle)
	_grid_view.show_solution_path(path)


func _on_puzzle_reset() -> void:
	_grid_view.refresh_all_tiles()
	_stats_display.hide_solved_message()
	_action_buttons.show_next_button(false)


func _on_reset_pressed() -> void:
	_game_manager.reset_puzzle()


func _on_next_puzzle_pressed() -> void:
	_start_new_game()
