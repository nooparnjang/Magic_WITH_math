extends Node
class_name PopupManager

const POPUP_SCENE: PackedScene = preload("res://scenes/shop/shop.tscn")
const POPUP_LAYER: int = 100

var popup_layer: CanvasLayer = null
var popup_instance: Control = null
var is_popup_open: bool = false


func _ready() -> void:
	# ทำให้ตัว manager ยังรับ input ได้ แม้เกมถูก pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ให้ปุ่มหรือ script อื่น ๆ หา manager ตัวนี้เจอ
	add_to_group("popup_manager")


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if event.is_echo():
		return

	toggle_popup()


func toggle_popup() -> void:
	if is_popup_open:
		close_popup()
	else:
		open_popup()


func open_popup() -> void:
	# ถ้ามี popup เปิดอยู่แล้ว ไม่ต้องเปิดซ้ำ
	if is_popup_open:
		return

	_create_popup_layer_if_needed()
	_create_popup_instance_if_needed()

	if popup_instance == null:
		return

	if popup_instance.has_method("show_popup"):
		popup_instance.show_popup()
	else:
		popup_instance.visible = true

	is_popup_open = true

	# pause หลังจาก popup พร้อมแล้ว
	get_tree().paused = true


func close_popup() -> void:
	# ปิด pause ก่อน เพื่อกันซีน/ปุ่มค้าง
	get_tree().paused = false

	if popup_instance != null and is_instance_valid(popup_instance):
		if popup_instance.has_method("hide_popup"):
			popup_instance.hide_popup()
		else:
			popup_instance.visible = false

		popup_instance.queue_free()
		popup_instance = null

	if popup_layer != null and is_instance_valid(popup_layer):
		popup_layer.queue_free()
		popup_layer = null

	is_popup_open = false


func go_to_main_menu() -> void:
	# ใช้ฟังก์ชันนี้เวลาอยากเปลี่ยนซีนจากใน popup
	close_popup()

	var main_menu_path := "res://scenes/mainmenu/MainMenu.tscn"
	var error := get_tree().change_scene_to_file(main_menu_path)

	if error != OK:
		push_error("เปลี่ยนซีนไป MainMenu ไม่ได้ เช็ก path นี้: " + main_menu_path)


func change_scene_from_popup(scene_path: String) -> void:
	# ฟังก์ชันกลาง เผื่อปุ่มอื่นอยากเปลี่ยนไปซีนอื่นด้วย
	close_popup()

	if scene_path.is_empty():
		push_error("scene_path ว่าง เปลี่ยนซีนไม่ได้")
		return

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("เปลี่ยนซีนไม่ได้ เช็ก path นี้: " + scene_path)


func _create_popup_layer_if_needed() -> void:
	if popup_layer != null and is_instance_valid(popup_layer):
		return

	popup_layer = CanvasLayer.new()
	popup_layer.name = "PopupLayer"
	popup_layer.layer = POPUP_LAYER

	# สำคัญ: popup layer ต้องทำงานตอน pause
	popup_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	get_tree().root.add_child(popup_layer)


func _create_popup_instance_if_needed() -> void:
	if popup_instance != null and is_instance_valid(popup_instance):
		return

	var instance := POPUP_SCENE.instantiate()

	if not instance is Control:
		push_error("popup root ต้องเป็น Control")
		return

	popup_instance = instance as Control
	popup_instance.name = "ShopPopup"

	# สำคัญ: popup ต้องทำงานตอน pause
	popup_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	popup_layer.add_child(popup_instance)
