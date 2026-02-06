extends Control

## Main game controller for Plumber Puzzle

@onready var game_board: GameBoard = $CenterContainer/VBoxContainer/GameBoardContainer/GameBoard
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var new_game_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/NewGameButton
@onready
var difficulty_option: OptionButton = $CenterContainer/VBoxContainer/ButtonContainer/DifficultyOption
@onready var win_panel: Panel = $WinPanel
@onready var win_label: Label = $WinPanel/WinLabel

var current_difficulty: int = 1
var moves_count: int = 0
var is_solved: bool = false


func _ready() -> void:
	_setup_ui()
	game_board.puzzle_solved.connect(_on_puzzle_solved)
	game_board.path_updated.connect(_on_path_updated)
	new_game_button.pressed.connect(_on_new_game_pressed)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	win_panel.hide()

	# Start first game
	_start_new_game()


func _setup_ui() -> void:
	difficulty_option.add_item("Easy (4x4)", 0)
	difficulty_option.add_item("Medium (5x5)", 1)
	difficulty_option.add_item("Hard (6x6)", 2)
	difficulty_option.add_item("Expert (7x7)", 3)
	difficulty_option.select(1)


func _start_new_game() -> void:
	moves_count = 0
	is_solved = false
	win_panel.hide()

	var sizes := [4, 5, 6, 7]
	var grid_size: int = sizes[current_difficulty]

	game_board.generate_puzzle(grid_size, grid_size, current_difficulty)
	_update_status()


func _update_status() -> void:
	if is_solved:
		status_label.text = "Solved! Moves: %d" % moves_count
	else:
		status_label.text = "Click pipes to rotate them"


func _on_puzzle_solved() -> void:
	if is_solved:
		return

	is_solved = true
	win_panel.show()
	win_label.text = "Puzzle Solved!\nMoves: %d" % moves_count
	_update_status()


func _on_path_updated(connected: int, total: int) -> void:
	if not is_solved:
		moves_count += 1
		status_label.text = "Connected: %d/%d | Moves: %d" % [connected, total, moves_count - 1]


func _on_new_game_pressed() -> void:
	_start_new_game()


func _on_difficulty_selected(index: int) -> void:
	current_difficulty = index


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and is_solved:
		_start_new_game()
