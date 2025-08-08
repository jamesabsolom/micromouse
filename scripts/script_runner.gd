extends VBoxContainer

@export var code_editor_path: NodePath
@export var run_button_path: NodePath
@export var save_button_path: NodePath
@export var load_button_path: NodePath
@export var file_dialog_path: NodePath
@export var maze_path: NodePath
@export var generate_button_path: NodePath
@export var settings_button_path: NodePath
@export var settings_popup_path: NodePath
@export var debug_output_path: NodePath
@export var maze_save_button_path: NodePath
@export var maze_load_button_path: NodePath
@export var docs_button_path: NodePath
@export var exit_button_path: NodePath
@export var new_maze_dialog_path: NodePath
@export var spinbox_w_path: NodePath
@export var spinbox_h_path: NodePath
@export var win_popup_path: NodePath
@export var time_holder_path: NodePath
@export var back_button_path: NodePath
@export var close_button_path: NodePath
@export var campaign_mode: bool

@onready var code_editor = get_node(code_editor_path)
@onready var run_button = get_node(run_button_path)
@onready var save_button = get_node(save_button_path)
@onready var load_button = get_node(load_button_path)
@onready var file_dialog = get_node(file_dialog_path)
@onready var maze = get_node(maze_path)
@onready var gen_button = null
@onready var settings_button = get_node(settings_button_path)
@onready var settings_popup = get_node(settings_popup_path)
@onready var debug_output = get_node(debug_output_path)
@onready var maze_save_button = null
@onready var maze_load_button = null
@onready var docs_button = get_node(docs_button_path)
@onready var exit_button = get_node(exit_button_path)
@onready var new_maze_dialog = null
@onready var spin_w = null
@onready var spin_h = null
@onready var win_popup = get_node(win_popup_path)
@onready var time_holder = get_node(time_holder_path)
@onready var back_button = get_node(back_button_path)
@onready var close_button = get_node(close_button_path)

@onready var interpreter_array = preload("res://scripts/interpreter/mouse_interpreter.gd").new().init()
@onready var interpreter = interpreter_array[0]
@onready var interpreter_helper = interpreter_array[1]
@onready var interpreter_parser = interpreter_array[2]

@export var mouse_path: NodePath  # drag the mouse into this in the Inspector

var last_highlighted_line := -1
var is_saving_script := false
var is_saving_maze := false
var is_loading_maze := false

func _ready():
	add_child(interpreter)
	interpreter.connect("error", Callable(self, "_on_error"))
	interpreter_helper.connect("error", Callable(self, "_on_error"))
	interpreter_parser.connect("error", Callable(self, "_on_error"))
	interpreter.line_changed.connect(_on_line_changed)
	interpreter.finished.connect(_on_execution_finished)
	interpreter_parser.finished.connect(_on_execution_finished)
	interpreter_helper.finished.connect(_on_execution_finished)
	run_button.pressed.connect(_on_run_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	settings_button.pressed.connect(_on_settings_pressed)
	docs_button.pressed.connect(_on_docs_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	if not campaign_mode:
		gen_button = get_node(generate_button_path)
		maze_save_button = get_node(maze_save_button_path)
		maze_load_button = get_node(maze_load_button_path)
		new_maze_dialog = get_node(new_maze_dialog_path)
		spin_w = get_node(spinbox_w_path)
		spin_h = get_node(spinbox_h_path)
		
		gen_button.pressed.connect(_on_generate_pressed)
		maze_save_button.pressed.connect(_on_maze_save_pressed)
		maze_load_button.pressed.connect(_on_maze_load_pressed)
		new_maze_dialog.connect("confirmed", Callable(self, "_on_new_maze_confirmed"))
		
func _on_run_pressed():
	if interpreter.running:
		interpreter.stop()
		run_button.text = "RUN CODE"
	else:
		debug_output.text = ""
		var code = code_editor.text
		var mouse = get_node(mouse_path)
		mouse.reset()
		await get_tree().create_timer(0.2).timeout
		interpreter.run_script(code, mouse, time_holder)
		run_button.text = "STOP"
	
func _on_line_changed(line_num: int):
	if last_highlighted_line >= 0 and last_highlighted_line < code_editor.get_line_count():
		code_editor.set_line_background_color(last_highlighted_line, Color(0, 0, 0, 0))  # Clear previous

	if line_num >= 0 and line_num < code_editor.get_line_count():
		var line_text = code_editor.get_line(line_num).strip_edges()
		if line_text == "":
			# If the line is blank, search downwards for next non-blank line to highlight instead
			var next_line := line_num + 1
			while next_line < code_editor.get_line_count():
				if code_editor.get_line(next_line).strip_edges() != "":
					line_num = next_line
					break
				next_line += 1
		code_editor.set_line_background_color(line_num, Color(0.2, 0.6, 1.0, 0.3))  # Highlight current
		code_editor.set_caret_line(line_num)
		code_editor.set_v_scroll(line_num)
		last_highlighted_line = line_num
	
func _on_execution_finished():
	if last_highlighted_line >= 0:
		code_editor.set_line_background_color(last_highlighted_line, Color(0, 0, 0, 0))
		last_highlighted_line = -1
	time_holder.stop()
	run_button.text = "RUN CODE"
		
func _on_save_pressed():
	is_saving_script = true
	is_saving_maze   = false
	is_loading_maze  = false
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.popup_centered()

func _on_load_pressed():
	is_saving_script = false
	is_saving_maze   = false
	is_loading_maze  = false
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()

func _on_maze_save_pressed():
	is_saving_script = false
	is_saving_maze   = true
	is_loading_maze  = false
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.popup_centered()

func _on_maze_load_pressed():
	is_saving_script = false
	is_saving_maze   = false
	is_loading_maze  = true
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	if is_saving_script:
		var f = FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(code_editor.text)
			f.close()
	elif is_saving_maze:
		maze.save_maze_text(path)
	elif is_loading_maze:
		maze.load_maze_text(path)
	else:
		# script load
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			code_editor.text = f.get_as_text()
			f.close()
			
func _on_Goal_body_entered(body):
	if body.name == "Mouse" and interpreter.running:
		print("🎉 Robot reached the goal!")
		interpreter.stop()  # Or call from scene root/UI	
		run_button.text = "RUN CODE"
		if campaign_mode:
			if Globals.campaign_level_num not in Globals.campaign_completed:
				Globals.campaign_completed.append(Globals.campaign_level_num)
		time_holder.stop()
		win_popup.popup_centered()
			
func _on_generate_pressed():
	# If code running, stop it...
	if interpreter.running:
		interpreter.stop()
		run_button.text = "RUN CODE"

	# Show the size dialog instead of immediately generating
	new_maze_dialog.popup_centered()

func _on_settings_pressed():
	# Show the popup (it will read current Globals in _ready())
	settings_popup.popup_centered()
	
func _on_error(msg: String) -> void:
	# append to the end of the existing text
	debug_output.text += "Error: %s\n" % msg
	# scroll all the way down
	debug_output.scroll_vertical = debug_output.get_line_count()
	
	run_button.call_deferred("set_text", "RUN CODE")

func _on_docs_pressed() -> void:
	OS.shell_open("https://jamesabsolom.github.io/micromouse/")

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _on_back_pressed() -> void:
	if campaign_mode:
		get_tree().change_scene_to_file("res://scenes/campaign_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _on_close_pressed() -> void:
	win_popup.hide()
	
func _on_new_maze_confirmed():
	# read desired size
	var w = int(spin_w.value)
	var h = int(spin_h.value)

	# set the maze’s exported vars
	maze.WIDTH = w
	maze.HEIGHT = h

	# regenerate
	maze.generate_maze()
	await get_tree().process_frame
	maze._update_cell_size()
	maze.mouse.resize_mouse(maze.CELL_SIZE)
	maze._position_goal()
	maze.queue_redraw()
