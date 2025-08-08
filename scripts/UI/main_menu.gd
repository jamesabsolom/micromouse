extends Node

@export var sandbox_button_path: NodePath
@export var campaign_button_path: NodePath
@export var quit_button_path: NodePath

@onready var sandbox_button = get_node(sandbox_button_path)
@onready var campaign_button = get_node(campaign_button_path)
@onready var quit_button = get_node(quit_button_path)

func _ready() -> void:
	sandbox_button.pressed.connect(_on_sandbox_pressed)
	campaign_button.pressed.connect(_on_campaign_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
func _on_sandbox_pressed():
	get_tree().change_scene_to_file("res://scenes/sandbox.tscn")
	
func _on_campaign_pressed():
	get_tree().change_scene_to_file("res://scenes/campaign_menu.tscn")
	
func _on_quit_pressed():
	get_tree().quit()
