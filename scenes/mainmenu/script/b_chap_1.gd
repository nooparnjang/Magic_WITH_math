extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	self.pressed.connect(_on_pressed)

func _on_pressed():
	get_tree().change_scene_to_file("res://scenes/gameplay/level1/intro_for_level_1.tscn")
