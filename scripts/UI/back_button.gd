extends Button


func _ready() -> void:
	self.pressed.connect(_on_select_pressed)
	
func _on_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
