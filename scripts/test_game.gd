extends Node2D


func _ready():
	print("Test scene _ready called")
	queue_redraw()


func _draw():
	# Direct draw test
	print("_draw() called!")
	draw_rect(Rect2(50, 50, 100, 100), Color.GREEN)
	draw_rect(Rect2(200, 200, 50, 50), Color.RED)
