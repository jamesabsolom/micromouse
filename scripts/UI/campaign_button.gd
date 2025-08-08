extends Control

@export var background_color_path: NodePath
@export var select_button_path: NodePath
@export var level_num: int
@export var campaign_level_address: String

@onready var background_color = get_node(background_color_path)
@onready var select_button = get_node(select_button_path)

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	if level_num in Globals.campaign_completed:
		background_color.set_color(Globals.complete_color)
	
	else:
		background_color.set_color(Globals.incomplete_color)
		
func _on_select_pressed():
	Globals.campaign_level = campaign_level_address
	Globals.campaign_level_num = level_num
	get_tree().change_scene_to_file("res://scenes/campaign_sim.tscn")
