class_name PipeTile
extends TextureButton

## Represents a single pipe tile that can be rotated

signal tile_rotated(tile: PipeTile)

## Pipe types and their connection directions (UP, RIGHT, DOWN, LEFT)
enum PipeType { STRAIGHT, CORNER, T_PIPE, CROSS, END, START, GOAL }  # Connects top-bottom  # Connects top-right (L-shaped)  # Connects left-right-bottom (T-shaped)  # Connects all four directions  # Only connects one direction (end cap)  # Start point (fixed, connects one direction)  # Goal point (fixed, connects one direction)

## Connection patterns for each pipe type at rotation 0
## Array of 4 bools: [UP, RIGHT, DOWN, LEFT]
const PIPE_CONNECTIONS := {
	PipeType.STRAIGHT: [true, false, true, false],
	PipeType.CORNER: [true, true, false, false],
	PipeType.T_PIPE: [false, true, true, true],
	PipeType.CROSS: [true, true, true, true],
	PipeType.END: [true, false, false, false],
	PipeType.START: [false, false, true, false],
	PipeType.GOAL: [true, false, false, false],
}

@export var pipe_type: PipeType = PipeType.STRAIGHT
@export var grid_position: Vector2i = Vector2i.ZERO
@export var is_locked: bool = false  # Start and Goal tiles are locked

var rotation_steps: int = 0  # 0-3, each step is 90 degrees
var is_connected_to_path: bool = false

# Preloaded textures
var textures := {}


func _ready() -> void:
	_load_textures()
	_update_texture()
	pressed.connect(_on_pressed)


func _load_textures() -> void:
	textures[PipeType.STRAIGHT] = preload("res://assets/pipe_straight.svg")
	textures[PipeType.CORNER] = preload("res://assets/pipe_corner.svg")
	textures[PipeType.T_PIPE] = preload("res://assets/pipe_t.svg")
	textures[PipeType.CROSS] = preload("res://assets/pipe_cross.svg")
	textures[PipeType.END] = preload("res://assets/pipe_end.svg")
	textures[PipeType.START] = preload("res://assets/pipe_start.svg")
	textures[PipeType.GOAL] = preload("res://assets/pipe_goal.svg")


func _update_texture() -> void:
	texture_normal = textures[pipe_type]
	pivot_offset = size / 2
	rotation = rotation_steps * PI / 2


func setup(type: PipeType, pos: Vector2i, locked: bool = false) -> void:
	pipe_type = type
	grid_position = pos
	is_locked = locked
	rotation_steps = 0
	_update_texture()


func rotate_pipe(clockwise: bool = true) -> void:
	if is_locked:
		return

	if clockwise:
		rotation_steps = (rotation_steps + 1) % 4
	else:
		rotation_steps = (rotation_steps + 3) % 4  # +3 is same as -1 mod 4

	_update_texture()
	tile_rotated.emit(self)


func get_connections() -> Array[bool]:
	## Returns current connections based on pipe type and rotation
	## Directions: 0=UP, 1=RIGHT, 2=DOWN, 3=LEFT
	## Visual rotation is clockwise, so after 1 rotation step (90° CW):
	## - What pointed UP now points RIGHT
	## - What pointed RIGHT now points DOWN
	## - What pointed DOWN now points LEFT
	## - What pointed LEFT now points UP
	var base_connections: Array = PIPE_CONNECTIONS[pipe_type]
	var rotated: Array[bool] = [false, false, false, false]

	for i in range(4):
		# After CW rotation, the connection at direction i came from direction (i + rotation) % 4
		# E.g., rotation=1: what's now at RIGHT(1) was originally at UP(0), so i=1 needs base[0]
		# Formula: rotated[i] = base[(i + rotation) % 4] -- NO wait, let me think again
		# If UP(0) rotates CW to become RIGHT(1), then:
		#   - rotated[1] should get base[0]
		#   - i.e., rotated[(0 + rotation) % 4] = base[0]
		# So: rotated[(original + rotation) % 4] = base[original]
		# Rearranging: rotated[i] = base[(i - rotation + 4) % 4] -- this is what we had!
		#
		# But the visual rotation uses: rotation = rotation_steps * PI / 2
		# Godot rotates counter-clockwise for positive angles!
		# So rotation_steps=1 means 90° CCW visually, not CW.
		# For CCW: UP becomes LEFT, not RIGHT
		# So: rotated[i] = base[(i + rotation_steps) % 4]
		var source_index := (i + rotation_steps) % 4
		rotated[i] = base_connections[source_index]

	return rotated


func has_connection(direction: int) -> bool:
	## Check if pipe connects in given direction (0=UP, 1=RIGHT, 2=DOWN, 3=LEFT)
	return get_connections()[direction]


func set_connected(connected: bool) -> void:
	is_connected_to_path = connected
	if connected:
		modulate = Color(0.5, 1.0, 0.5)  # Green tint for connected pipes
	else:
		modulate = Color.WHITE


func _on_pressed() -> void:
	rotate_pipe(true)
