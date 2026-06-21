extends Control

@export_file("*.tscn")
var enter_scene_path: String = "res://scenes/gameplay/level1/intro_for_level_1.tscn"

@export_file("*.tscn")
var backspace_scene_path: String = "res://scenes/menu/select_level.tscn"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			change_scene(enter_scene_path)

		elif event.keycode == KEY_BACKSPACE:
			change_scene(backspace_scene_path)


func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_error("ยังไม่ได้ใส่ scene_path")
		return

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("เปลี่ยนซีนไม่ได้: " + scene_path)
