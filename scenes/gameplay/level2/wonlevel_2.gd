extends Control

@export var required_item: String = "Gem2"

# โหนดที่อยากซ่อนตอน popup เปิด
@export var node_to_hide: Node

@export_file("*.tscn")
var enter_scene_path: String = "res://scenes/gameplay/level1/intro_for_level_1.tscn"

@export_file("*.tscn")
var backspace_scene_path: String = "res://scenes/menu/select_level.tscn"

var already_triggered: bool = false


func _ready() -> void:
	hide()

	# สำคัญมาก ถ้าเกม pause แล้ว popup ยังต้องรับ input ได้
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _process(_delta: float) -> void:
	if already_triggered:
		return

	if BlessingManager.get_item_count(required_item) > 0:
		already_triggered = true
		open_popup_and_pause()


func open_popup_and_pause() -> void:
	if node_to_hide != null:
		node_to_hide.hide()

	show()
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			change_scene(enter_scene_path)

		elif event.keycode == KEY_BACKSPACE:
			change_scene(backspace_scene_path)


func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_error("ยังไม่ได้ใส่ scene_path")
		return

	# ต้อง unpause ก่อนเปลี่ยนซีน ไม่งั้นซีนใหม่อาจค้าง pause
	get_tree().paused = false

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("เปลี่ยนซีนไม่ได้: " + scene_path)
