extends CharacterBody2D

@export var move_speed := 10
@export var rotation_speed := 90
@export var move_delay := 0.1  # seconds
@export var turn_delay := 0.01 # seconds

var start_position: Vector2
var start_rotation: float

func _ready():
	print("mouse comms setup")
	start_position = position
	start_rotation = rotation

func move_forward():
	var direction = Vector2.RIGHT.rotated(rotation)
	velocity = direction * move_speed
	move_and_collide(velocity)

func turn_left():
	rotation -= deg_to_rad(1)  # Turn 15 degrees left

func turn_right():
	rotation += deg_to_rad(1)  # Turn 15 degrees right

func read_sensor(name: String) -> bool:
	match name:
		"FRONT PROX":
			print("Front Sensor Detected as", $FrontProx.is_colliding())
			return $FrontProx.is_colliding()
		"LEFT PROX":
			return $LeftProx.is_colliding()
		"RIGHT PROX":
			return $RightProx.is_colliding()
		_:
			return false
			
func reset():
	position = start_position
	rotation = start_rotation
