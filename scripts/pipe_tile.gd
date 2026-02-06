extends Panel

class_name PipeTile

enum PipeType { STRAIGHT, CORNER, T_JUNCTION, CROSS, START, END }

var pipe_type: PipeType = PipeType.STRAIGHT
var rotation_angle: int = 0
var grid_pos: Vector2i = Vector2i.ZERO
var is_solved: bool = false

const TILE_SIZE = 90


func _ready():
	custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	size = Vector2(TILE_SIZE, TILE_SIZE)


func _draw():
	match pipe_type:
		PipeType.START:
			_draw_start_point()
		PipeType.END:
			_draw_end_point()
		PipeType.STRAIGHT:
			_draw_straight()
		PipeType.CORNER:
			_draw_corner()
		PipeType.T_JUNCTION:
			_draw_t_junction()
		PipeType.CROSS:
			_draw_cross()


func _draw_start_point():
	draw_circle(Vector2(TILE_SIZE / 2, TILE_SIZE / 2), 20, Color.GREEN)
	draw_circle(Vector2(TILE_SIZE / 2, TILE_SIZE / 2), 14, Color.LIGHT_GREEN)


func _draw_end_point():
	draw_circle(Vector2(TILE_SIZE / 2, TILE_SIZE / 2), 20, Color.RED)
	draw_circle(Vector2(TILE_SIZE / 2, TILE_SIZE / 2), 14, Color.LIGHT_CORAL)


func _draw_straight():
	var center = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	if rotation_angle == 0 or rotation_angle == 180:
		draw_line(Vector2(center.x, 0), Vector2(center.x, TILE_SIZE), Color.BLUE, 16)
	else:
		draw_line(Vector2(0, center.y), Vector2(TILE_SIZE, center.y), Color.BLUE, 16)


func _draw_corner():
	var center = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	var connections = _get_corner_connections()

	for dir in connections:
		var end_pos = center + dir * (TILE_SIZE / 2)
		draw_line(center, end_pos, Color.BLUE, 16)


func _draw_t_junction():
	var center = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	var connections = _get_t_connections()

	for dir in connections:
		var end_pos = center + dir * (TILE_SIZE / 2)
		draw_line(center, end_pos, Color.BLUE, 16)


func _draw_cross():
	var center = Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

	for dir in directions:
		var end_pos = center + dir * (TILE_SIZE / 2)
		draw_line(center, end_pos, Color.BLUE, 16)


func _get_corner_connections() -> Array:
	match rotation_angle:
		0:
			return [Vector2.UP, Vector2.RIGHT]
		90:
			return [Vector2.RIGHT, Vector2.DOWN]
		180:
			return [Vector2.DOWN, Vector2.LEFT]
		270:
			return [Vector2.LEFT, Vector2.UP]
	return []


func _get_t_connections() -> Array:
	match rotation_angle:
		0:
			return [Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
		90:
			return [Vector2.UP, Vector2.DOWN, Vector2.RIGHT]
		180:
			return [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		270:
			return [Vector2.UP, Vector2.DOWN, Vector2.LEFT]
	return []


func get_connections() -> Array:
	match pipe_type:
		PipeType.START:
			return [Vector2.DOWN]
		PipeType.END:
			return [Vector2.UP]
		PipeType.STRAIGHT:
			if rotation_angle == 0 or rotation_angle == 180:
				return [Vector2.UP, Vector2.DOWN]
			else:
				return [Vector2.LEFT, Vector2.RIGHT]
		PipeType.CORNER:
			return _get_corner_connections()
		PipeType.T_JUNCTION:
			return _get_t_connections()
		PipeType.CROSS:
			return [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	return []


func rotate_cw():
	rotation_angle = (rotation_angle + 90) % 360
	queue_redraw()


func set_pipe_type(new_type: PipeType):
	pipe_type = new_type
	rotation_angle = 0
	queue_redraw()


func set_solved(solved: bool):
	is_solved = solved
	modulate = Color.YELLOW if solved else Color.WHITE
