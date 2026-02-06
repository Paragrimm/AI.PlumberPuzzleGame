class_name StatsDisplay
extends HBoxContainer
## Zeigt Spielstatistiken an.

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
