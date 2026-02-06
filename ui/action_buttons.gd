class_name ActionButtons
extends HBoxContainer
## Verwaltet Aktions-Buttons.

## Signal wenn Reset gedrückt wird.
signal reset_pressed

## Signal wenn "Nächstes Puzzle" gedrückt wird.
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


func show_next_button(should_show: bool) -> void:
	_next_button.visible = should_show
