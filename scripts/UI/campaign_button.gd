extends Control

@export var background_color_path: NodePath
@export var select_button_path: NodePath
@export var level_num: int
@export var campaign_level_address: String
@export var time_label_path: NodePath  # <— new: drag in a Label to show the time

@onready var background_color = get_node(background_color_path)
@onready var select_button = get_node(select_button_path)
@onready var time_label = get_node(time_label_path)

@onready var progress_io = load("res://scripts/progress_io.gd")

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	progress_io.load_into_globals()

	if level_num in Globals.campaign_results:
		# Level completed
		background_color.color = Globals.complete_color

		# Show recorded time, formatted to 2 decimals
		var t = Globals.campaign_results[level_num]
		time_label.text = str(t).pad_decimals(2) + " s"
	else:
		# Not yet done
		background_color.color = Globals.incomplete_color
		time_label.text = ""
	time_label.visible = level_num in Globals.campaign_results
		
func _on_select_pressed():
	Globals.campaign_level = campaign_level_address
	Globals.campaign_level_num = level_num
	get_tree().change_scene_to_file("res://scenes/campaign_sim.tscn")
