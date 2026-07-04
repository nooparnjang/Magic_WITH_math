extends Button

func _pressed() -> void:
	var quiz_ui = get_tree().get_first_node_in_group("quiz_ui")

	if quiz_ui == null:
		push_error("QuizUI not found in group!")
		return

	quiz_ui.call("_close")

func _ready():
	pressed.connect(func():
		print("REAL BUTTON CLICKED")
	)
