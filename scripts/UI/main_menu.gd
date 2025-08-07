extends Node

@export var sandbox_button_path: NodePath

@onready var sandbox_button = get_node(sandbox_button_path)

func _ready() -> void:
	sandbox_button.pressed.connect(_on_sandbox_pressed)
	
func _on_sandbox_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
