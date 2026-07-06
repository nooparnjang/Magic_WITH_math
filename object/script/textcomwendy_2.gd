extends Control

@export_file("*.tscn")
var back_scene: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_back_pressed():
	change_scene()

func change_scene():
	get_tree().paused = false

	if back_scene != "":
		get_tree().change_scene_to_file(back_scene)
	else:
		push_warning("Back scene is not assigned!")
