extends Button

const MAIN_MENU_PATH := "res://scenes/mainmenu/MainMenu.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	print("Go to Main Menu button pressed")

	var managers := get_tree().get_nodes_in_group("popup_manager")

	if managers.size() > 0:
		var popup_manager := managers[0]

		if popup_manager.has_method("go_to_main_menu"):
			popup_manager.go_to_main_menu()
			return

	# fallback เผื่อหา PopupManager ไม่เจอ
	get_tree().paused = false

	_free_parent_canvas_layer()

	var error := get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if error != OK:
		push_error("เปลี่ยนซีนไป MainMenu ไม่ได้ เช็ก path นี้: " + MAIN_MENU_PATH)


func _free_parent_canvas_layer() -> void:
	var current_node: Node = self

	while current_node != null:
		if current_node is CanvasLayer:
			current_node.queue_free()
			return

		current_node = current_node.get_parent()
