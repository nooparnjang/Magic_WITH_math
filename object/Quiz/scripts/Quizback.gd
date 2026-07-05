extends Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	print("REAL BUTTON CLICKED")

	if QuizUI == null:
		push_error("QuizUI AutoLoad missing!")
		return

	QuizUI.call_deferred("_close")
