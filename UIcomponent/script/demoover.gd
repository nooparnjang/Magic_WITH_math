extends Control

@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/mainmenu/MainMenu.tscn"

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func show_demo_end() -> void:
	visible = true
	grab_focus() # 👈 สำคัญสำหรับ Control

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().change_scene_to_file(main_menu_scene_path)
