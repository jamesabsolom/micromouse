extends VBoxContainer

@onready var code_editor = $CodeEditor
@onready var run_button = $HBoxContainer/RunButton
@onready var stop_button = $HBoxContainer/StopButton
@onready var interpreter = preload("res://scripts/mouse_interpreter.gd").new()

@export var mouse_path: NodePath  # drag the mouse into this in the Inspector

func _ready():
	add_child(interpreter)
	run_button.pressed.connect(_on_run_pressed)
	stop_button.pressed.connect(_on_Stop_pressed)

func _on_run_pressed():
	var code = code_editor.text
	var mouse = get_node(mouse_path)
	interpreter.run_script(code, mouse)
	
func _on_Stop_pressed():
	interpreter.stop()
