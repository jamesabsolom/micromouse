extends CharacterBody2D

@export var move_speed := 50
@export var rotation_speed := 90
@export var move_delay := 0.2  # seconds

func _ready():
	print("mouse comms setup")

func _physics_process(delta):
	if Input.is_action_pressed("ui_left"):
		rotation_degrees -= rotation_speed * delta
	elif Input.is_action_pressed("ui_right"):
		rotation_degrees += rotation_speed * delta

	var direction = Vector2.RIGHT.rotated(rotation)
	var motion = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		motion = direction * move_speed

	velocity = motion
	move_and_slide()

func move_forward():
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * 10  # Or use velocity for smoother movement

func turn_left():
	rotation -= deg_to_rad(15)  # Turn 15 degrees left

func turn_right():
	rotation += deg_to_rad(15)  # Turn 15 degrees right

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
