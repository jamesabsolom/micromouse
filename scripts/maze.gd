extends Node2D

const WIDTH = 11
const HEIGHT = 11

var CELL_SIZE: float
var grid = []
var start = Vector2(0, 0)
var end = Vector2(WIDTH - 1, HEIGHT - 1)

@export var background_path: NodePath
@export var mouse_path: NodePath
@export var splitter_path: NodePath

@onready var goal = $Goal
@onready var background = get_node(background_path) as ColorRect
@onready var mouse = get_node(mouse_path)
@onready var splitter = get_node(splitter_path)

func _ready():
	generate_maze()
	# Wait for layout then set split and cell size
	await get_tree().process_frame
	splitter.set_split_offset(get_viewport_rect().size.x / 2)
	_update_cell_size()
	mouse.resize_mouse(CELL_SIZE)
	queue_redraw()
	_position_goal()
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_resized"))

func _update_cell_size():
	var vp_width = get_viewport_rect().size.x / 2
	CELL_SIZE = vp_width / WIDTH

func _position_goal():
	var goal_pos = end * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
	goal.global_position = goal_pos
	var shape = goal.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		shape.radius = CELL_SIZE / 3
	elif shape is RectangleShape2D:
		shape.extents = Vector2(CELL_SIZE/3, CELL_SIZE/3)

func generate_maze():
	grid.clear()
	for y in range(HEIGHT):
		var row = []
		for x in range(WIDTH):
			var cell_center = Vector2(x * CELL_SIZE + CELL_SIZE / 2, y * CELL_SIZE + CELL_SIZE / 2)
			var cell = {
				"grid_pos": Vector2i(x, y),
				"world_pos": cell_center,
				"walls": ["top", "bottom", "left", "right"]
			}
			row.append(cell)
		grid.append(row)

	var visited = []
	_carve_passage(0, 0, visited)

func _carve_passage(x, y, visited):
	visited.append(Vector2(x, y))
	var dirs = [Vector3(0, -1, 0), Vector3(1, 0, 1), Vector3(0, 1, 2), Vector3(-1, 0, 3)]
	dirs.shuffle()
	for d in dirs:
		var nx = x + int(d.x)
		var ny = y + int(d.y)
		if nx in range(WIDTH) and ny in range(HEIGHT) and Vector2(nx, ny) not in visited:
			var cur = grid[y][x]["walls"]
			var nxt = grid[ny][nx]["walls"]
			match int(d.z):
				0:
					cur.erase("top"); nxt.erase("bottom")
				1:
					cur.erase("right"); nxt.erase("left")
				2:
					cur.erase("bottom"); nxt.erase("top")
				3:
					cur.erase("left");  nxt.erase("right")
			_carve_passage(nx, ny, visited)

func _draw():
	draw_maze()

func spawn_wall_line(p1: Vector2, p2: Vector2):
	var wall = StaticBody2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	var length = p1.distance_to(p2)
	rect.extents = Vector2(length / 2.0, 2)
	shape.shape = rect
	shape.rotation = p1.angle_to_point(p2)
	shape.position = (p1 + p2) / 2.0
	wall.add_child(shape)
	add_child(wall)

func draw_maze():
	var wall_color = Color(1,1,1)
	var grid_line = Color(0.8, 0.8, 0.8, 0.3)

	# Draw light grid lines where no wall exists
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var walls = grid[y][x]
			var px = x * CELL_SIZE
			var py = y * CELL_SIZE
			var p1 = Vector2(px, py)
			var p2 = Vector2(px + CELL_SIZE, py)
			var p3 = Vector2(px + CELL_SIZE, py + CELL_SIZE)
			var p4 = Vector2(px, py + CELL_SIZE)

			if "top" not in walls:
				draw_line(p1, p2, grid_line, 1)
			if "right" not in walls:
				draw_line(p2, p3, grid_line, 1)
			if "bottom" not in walls:
				draw_line(p3, p4, grid_line, 1)
			if "left" not in walls:
				draw_line(p4, p1, grid_line, 1)

	# Draw solid walls
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var walls = grid[y][x]["walls"]
			var px = x * CELL_SIZE
			var py = y * CELL_SIZE
			var p1 = Vector2(px, py)
			var p2 = Vector2(px + CELL_SIZE, py)
			var p3 = Vector2(px + CELL_SIZE, py + CELL_SIZE)
			var p4 = Vector2(px, py + CELL_SIZE)

			if "top" in walls:
				draw_line(p1, p2, wall_color, 4)
				spawn_wall_line(p1, p2)
			if "right" in walls:
				draw_line(p2, p3, wall_color, 4)
				spawn_wall_line(p2, p3)
			if "bottom" in walls:
				draw_line(p3, p4, wall_color, 4)
				spawn_wall_line(p3, p4)
			if "left" in walls:
				draw_line(p4, p1, wall_color, 4)
				spawn_wall_line(p4, p1)

	# Draw start and end
	var start_pos = start * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
	mouse.start_position = start_pos
	mouse.reset()
	var end_pos = end * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
	draw_circle(start_pos, CELL_SIZE * 0.2, Color(0,1,0))
	draw_circle(end_pos, CELL_SIZE * 0.2, Color(1,0,0))

func _on_viewport_resized():
	splitter.set_split_offset(get_viewport_rect().size.x / 2)
	_update_cell_size()
	mouse.resize_mouse(CELL_SIZE)
	queue_redraw()
