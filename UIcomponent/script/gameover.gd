extends Control

@export_file("*.tscn") var main_menu_scene: String = "res://scenes/mainmenu/MainMenu.tscn"

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode = Control.FOCUS_ALL

func show_game_over() -> void:
	visible = true
	grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		return_to_main_menu()

func return_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)
