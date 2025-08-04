extends VBoxContainer

@onready var code_editor = $CodeEditor
@onready var run_button = $HBoxContainer/RunButton
@onready var stop_button = $HBoxContainer/StopButton
@onready var save_button = $HBoxContainer/SaveButton
@onready var load_button = $HBoxContainer/LoadButton
@onready var file_dialog = $FileDialog
@onready var interpreter = preload("res://scripts/mouse_interpreter.gd").new()

@export var mouse_path: NodePath  # drag the mouse into this in the Inspector

var last_highlighted_line := -1
var is_saving := false

func _ready():
	add_child(interpreter)
	interpreter.line_changed.connect(_on_line_changed)
	interpreter.finished.connect(_on_execution_finished)
	run_button.pressed.connect(_on_run_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
func _on_run_pressed():
	if interpreter.running:
		interpreter.stop()
		run_button.text = "RUN CODE"
	else:
		var code = code_editor.text
		var mouse = get_node(mouse_path)
		mouse.reset()
		await get_tree().create_timer(0.5).timeout
		interpreter.run_script(code, mouse)
		run_button.text = "STOP"
	
func _on_line_changed(line_num: int):
	if last_highlighted_line >= 0:
		code_editor.set_line_background_color(last_highlighted_line, Color(0, 0, 0, 0))  # Clear previous

	if line_num > -1:
		code_editor.set_line_background_color(line_num, Color(0.2, 0.6, 1.0, 0.3))  # Highlight current
		code_editor.set_caret_line(line_num)
		code_editor.set_v_scroll(line_num)
		last_highlighted_line = line_num
	
func _on_execution_finished():
	if last_highlighted_line >= 0:
		code_editor.set_line_background_color(last_highlighted_line, Color(0, 0, 0, 0))
		last_highlighted_line = -1
		
func _on_save_pressed():
	is_saving = true
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.popup_centered()

func _on_load_pressed():
	is_saving = false
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	if is_saving:
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(code_editor.text)
	else:
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			code_editor.text = file.get_as_text()
			
func _on_Goal_body_entered(body):
	print(body.name)
	if body.name == "Mouse":
		print("🎉 Robot reached the goal!")
		interpreter.stop()  # Or call from scene root/UI	
		run_button.text = "RUN CODE"
