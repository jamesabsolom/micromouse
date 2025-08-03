extends Node2D

const CELL_SIZE = 50
const WIDTH = 10
const HEIGHT = 10

var grid = []
var start = Vector2(0, 0)
var end = Vector2(WIDTH - 1, HEIGHT - 1)

@onready var goal = $Goal

func _ready():
	generate_maze()
	queue_redraw()
	var goal_pos = end * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	goal.global_position = goal_pos

	# Resize the collision shape to fit within the goal cell
	var shape = goal.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		shape.radius = CELL_SIZE / 3
	elif shape is RectangleShape2D:
		shape.extents = Vector2(CELL_SIZE / 3, CELL_SIZE / 3)
		
func generate_maze():
	grid = []
	for y in HEIGHT:
		var row = []
		for x in WIDTH:
			row.append(["top", "bottom", "left", "right"])
		grid.append(row)

	var visited = []
	_carve_passage(0, 0, visited)

func _carve_passage(x, y, visited):
	visited.append(Vector2(x, y))
	var directions = [
		Vector3(0, -1, 0),  # top
		Vector3(1, 0, 1),   # right
		Vector3(0, 1, 2),   # bottom
		Vector3(-1, 0, 3)   # left
	]
	directions.shuffle()

	for d in directions:
		var nx = x + int(d.x)
		var ny = y + int(d.y)
		if nx >= 0 and nx < WIDTH and ny >= 0 and ny < HEIGHT and not Vector2(nx, ny) in visited:
			var current = grid[y][x]
			var next = grid[ny][nx]

			match int(d.z):
				0:
					current.erase("top")
					next.erase("bottom")
				1:
					current.erase("right")
					next.erase("left")
				2:
					current.erase("bottom")
					next.erase("top")
				3:
					current.erase("left")
					next.erase("right")

			_carve_passage(nx, ny, visited)

func _draw():
	draw_maze()

func spawn_wall_line(p1: Vector2, p2: Vector2):
	var wall = StaticBody2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	
	# Length & angle 
	var length = p1.distance_to(p2)
	rect.extents = Vector2(length / 2.0, 1)

	# Position & rotation
	shape.shape = rect
	shape.rotation = p1.angle_to_point(p2)
	shape.position = (p1 + p2) / 2.0

	wall.add_child(shape)
	add_child(wall)

func draw_maze():
	var wall_color = Color.WHITE
	for y in HEIGHT:
		for x in WIDTH:
			var walls = grid[y][x]
			var px = x * CELL_SIZE
			var py = y * CELL_SIZE
			var p1 = Vector2(px, py)
			var p2 = Vector2(px + CELL_SIZE, py)
			var p3 = Vector2(px + CELL_SIZE, py + CELL_SIZE)
			var p4 = Vector2(px, py + CELL_SIZE)

			if "top" in walls:
				draw_line(p1, p2, wall_color, 2)
				spawn_wall_line(p1, p2)
			if "right" in walls:
				draw_line(p2, p3, wall_color, 2)
				spawn_wall_line(p2, p3)
			if "bottom" in walls:
				draw_line(p3, p4, wall_color, 2)
				spawn_wall_line(p3, p4)
			if "left" in walls:
				draw_line(p4, p1, wall_color, 2)
				spawn_wall_line(p4, p1)

	# Draw start and end
	var start_pos = start * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	var end_pos = end * CELL_SIZE + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
	draw_circle(start_pos, 10, Color.GREEN)
	draw_circle(end_pos, 10, Color.RED)
	
func _on_Goal_body_entered(body):
	if body.name == "Mouse":
		print("🎉 Robot reached the goal!")
		body.get_parent().interpreter.stop()  # Or call from scene root/UI	
