extends Button

@export_file("*.tscn")
var target_scene_path: String = "res://scenes/gameplay/level1/intro_for_level_1.tscn"


func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if target_scene_path.is_empty():
		push_error("Button: ยังไม่ได้ใส่ target_scene_path")
		return

	var error := get_tree().change_scene_to_file(target_scene_path)

	if error != OK:
		push_error("Button: เปลี่ยนซีนไม่ได้ path = " + target_scene_path)
