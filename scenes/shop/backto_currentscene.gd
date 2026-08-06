extends Button


func _on_pressed() -> void:
	var ev = InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
