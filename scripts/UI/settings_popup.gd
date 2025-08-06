extends PopupPanel

@export var cb_interpreter_debug_path : NodePath
@export var cb_sensor_debug_path : NodePath
@export var cb_print_parse_tree_path : NodePath
@export var btn_ok_path : NodePath
@export var btn_cancel_path : NodePath
@export var slider_mouse_speed_path : NodePath
@export var lbl_speed_value_path : NodePath

@onready var cb_interpreter_debug = get_node(cb_interpreter_debug_path)
@onready var cb_sensor_debug = get_node(cb_sensor_debug_path)
@onready var cb_print_parse_tree = get_node(cb_print_parse_tree_path)
@onready var btn_ok = get_node(btn_ok_path)
@onready var btn_cancel = get_node(btn_cancel_path)
@onready var slider_mouse_speed = get_node(slider_mouse_speed_path)
@onready var lbl_speed_value = get_node(lbl_speed_value_path)

func _ready():
	# Initialize checkbox states from Globals
	cb_interpreter_debug.button_pressed = Globals.interpreter_debug_enabled
	cb_sensor_debug.button_pressed = Globals.sensor_debug
	cb_print_parse_tree.button_pressed = Globals.print_parse_tree
	
	# init slider & label
	slider_mouse_speed.value = Globals.move_speed
	lbl_speed_value.text = str(int(slider_mouse_speed.value))
	slider_mouse_speed.connect("value_changed", Callable(self, "_on_speed_changed"))

	btn_ok.pressed.connect(_on_ok)
	btn_cancel.pressed.connect(_on_cancel)
	
func _on_speed_changed(value: float) -> void:
	lbl_speed_value.text = str(int(value))
	
func _on_ok():
	# Write back into Globals
	Globals.interpreter_debug_enabled = cb_interpreter_debug.button_pressed
	Globals.sensor_debug = cb_sensor_debug.button_pressed
	Globals.print_parse_tree = cb_print_parse_tree.button_pressed
	
	Globals.move_speed = int(slider_mouse_speed.value)
	hide()

func _on_cancel():
	hide()
