extends Control


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		close_ui()


func _on_back_pressed():
	close_ui()


func close_ui():
	get_tree().paused = false
	queue_free()
