extends CharacterBody2D

@export var move_speed := 0
@export var maze_path : NodePath

var start_position: Vector2
var start_rotation: float

@onready var maze = get_node(maze_path)
@onready var front_prox: RayCast2D = $FrontProx
@onready var left_prox: RayCast2D = $LeftProx
@onready var right_prox: RayCast2D = $RightProx
@onready var starting_scale = self.scale

func _ready() -> void:
	Globals.mouse_ref = self
	move_speed = Globals.move_speed
	start_position = position
	start_rotation = rotation
	# Always enable processing so _process and _draw run each frame
	set_process(true)
	# Ensure raycasts are active
	for rc in [front_prox, left_prox, right_prox]:
		rc.enabled = true
	await get_tree().process_frame

func _process(_delta: float) -> void:
	# Update raycasts and redraw each frame
	for rc in [front_prox, left_prox, right_prox]:
		rc.force_raycast_update()
	queue_redraw()

func _draw() -> void:
	# Draw each RayCast2D; red when colliding, green when not
	for rc in [front_prox, left_prox, right_prox]:
		var origin = to_local(rc.global_position)
		var endpoint = to_local(rc.global_transform * rc.target_position)
		var color = Color.RED if rc.is_colliding() else Color.GREEN
		draw_line(origin, endpoint, color, 2)

func move_forward() -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	velocity = direction * move_speed
	move_and_collide(velocity)

func turn_left() -> void:
	rotation -= deg_to_rad(1)

func turn_right() -> void:
	rotation += deg_to_rad(1)

func read_sensor(name: String) -> bool:
	match name:
		"FRONT PROX":
			if Globals.sensor_debug:
				print("Front Sensor Detected as", front_prox.is_colliding())
			return front_prox.is_colliding()
		"LEFT PROX":
			return left_prox.is_colliding()
		"RIGHT PROX":
			return right_prox.is_colliding()
		_:
			return false

func reset() -> void:
	position = start_position
	rotation = start_rotation
	
func resize_mouse(cell_size: float):
	var ratio = cell_size/50
	self.scale.x = starting_scale.x * ratio
	self.scale.y = starting_scale.y * ratio
	
func get_current_cell() -> Vector2i:
	var CELL_SIZE = maze.CELL_SIZE
	return Vector2i(floor(position.x / CELL_SIZE), floor(position.y / CELL_SIZE))

func is_facing_cell(target: Vector2i) -> bool:
	var CELL_SIZE = maze.CELL_SIZE
	var facing_dir = Vector2.RIGHT.rotated(rotation).normalized()
	var target_world = Vector2(target.x * CELL_SIZE + CELL_SIZE / 2, target.y * CELL_SIZE + CELL_SIZE / 2)
	var to_target = (target_world - global_position).normalized()
	var angle_diff = facing_dir.angle_to(to_target)
	#print(angle_diff)
	return abs(angle_diff) < 0.01  # ~8.6 degrees tolerance
	
func get_cell_center(grid_pos: Vector2i) -> Vector2:
	var cell_size = maze.CELL_SIZE  # or whatever your tile size is
	return Vector2(grid_pos.x * cell_size + cell_size / 2, grid_pos.y * cell_size + cell_size / 2)

func snap_to_cell_center(cell: Vector2i) -> void:
	var cell_size := Vector2(maze.CELL_SIZE, maze.CELL_SIZE)  # Adjust to match your grid
	var center: Vector2 = Vector2(cell) * cell_size + cell_size / 2
	global_position = center
