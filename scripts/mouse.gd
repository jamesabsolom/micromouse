extends CharacterBody2D

@export var move_speed := 0

var start_position: Vector2
var start_rotation: float

@onready var front_prox: RayCast2D = $FrontProx
@onready var left_prox: RayCast2D = $LeftProx
@onready var right_prox: RayCast2D = $RightProx

func _ready() -> void:
	move_speed = Globals.move_speed
	start_position = position
	start_rotation = rotation
	# Always enable processing so _process and _draw run each frame
	set_process(true)
	# Ensure raycasts are active
	for rc in [front_prox, left_prox, right_prox]:
		rc.enabled = true

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
