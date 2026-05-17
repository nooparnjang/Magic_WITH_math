extends Node

signal selected_item_changed(item_id: String)

@export var selecting_icon: Sprite2D

const ITEM_TEXTURE_PATHS: Dictionary = {
	"": "res://assets/UI/selecting/handSelect.png",
	"bomb": "res://assets/UI/selecting/bombSelect.png",
	"scrap": "res://assets/UI/selecting/bombSelect.png",
	"gem": "res://assets/UI/selecting/bombSelect.png",
	"potion": "res://assets/UI/selecting/bombSelect.png",
	"stamina_potion": "res://assets/UI/selecting/bombSelect.png",
	"coin": "res://assets/UI/selecting/bombSelect.png",
	"engine_part": "res://assets/UI/selecting/engineSelect.png"
}

const ITEM_DISPLAY_NAMES: Dictionary = {
	"": "มือเปล่า",
	"bomb": "ระเบิด",
	"scrap": "เศษเหล็ก",
	"gem": "อัญมณี",
	"potion": "ยา",
	"stamina_potion": "ยาฟื้นสตามิน่า",
	"coin": "เหรียญ",
	"engine_part": "ชิ้นส่วนเครื่องยนต์"
}

var item_texture_map: Dictionary = {}

var selectable_items: Array[String] = [""]
var selected_item_index: int = 0
var selected_item_id: String = ""


func _ready() -> void:
	_build_item_texture_map()
	refresh_selectable_items()
	update_selected_item_visual(false)

	if BlessingManager.has_signal("item_changed"):
		if not BlessingManager.item_changed.is_connected(_on_inventory_item_changed):
			BlessingManager.item_changed.connect(_on_inventory_item_changed)

	if BlessingManager.has_signal("inventory_reset"):
		if not BlessingManager.inventory_reset.is_connected(_on_inventory_reset):
			BlessingManager.inventory_reset.connect(_on_inventory_reset)


func _build_item_texture_map() -> void:
	item_texture_map.clear()

	for item_id in ITEM_TEXTURE_PATHS.keys():
		var path: String = String(ITEM_TEXTURE_PATHS[item_id])
		var item_texture := load(path) as Texture2D

		if item_texture == null:
			push_warning("โหลด texture ไม่ได้: " + String(item_id) + " จาก path: " + path)
			continue

		item_texture_map[item_id] = item_texture


func refresh_selectable_items() -> void:
	selectable_items.clear()
	selectable_items.append("")

	var all_items: Dictionary = BlessingManager.get_all_items()

	for item_id in all_items.keys():
		var count: int = int(all_items[item_id])
		if count > 0:
			selectable_items.append(String(item_id))

	if selected_item_index >= selectable_items.size():
		selected_item_index = 0

	if selected_item_index < 0:
		selected_item_index = 0

	selected_item_id = selectable_items[selected_item_index]


func cycle_selected_item(direction: int) -> void:
	refresh_selectable_items()

	if selectable_items.is_empty():
		return

	selected_item_index += direction

	if selected_item_index >= selectable_items.size():
		selected_item_index = 0
	elif selected_item_index < 0:
		selected_item_index = selectable_items.size() - 1

	selected_item_id = selectable_items[selected_item_index]

	print("ตอนนี้ถือ:", get_selected_item_display_name(), "id =", selected_item_id)

	update_selected_item_visual(true)
	selected_item_changed.emit(selected_item_id)


func update_selected_item_visual(show_popup: bool = true) -> void:
	if selecting_icon == null:
		return

	var item_texture: Texture2D = item_texture_map.get(selected_item_id, null)

	if item_texture == null:
		if selecting_icon.has_method("hide_item"):
			selecting_icon.hide_item()
		else:
			selecting_icon.visible = false
		return

	if show_popup:
		if selecting_icon.has_method("show_item"):
			selecting_icon.show_item(item_texture)
		else:
			selecting_icon.texture = item_texture
			selecting_icon.visible = true
	else:
		selecting_icon.texture = item_texture
		selecting_icon.visible = false
		selecting_icon.modulate.a = 1.0


func get_selected_item_id() -> String:
	return selected_item_id


func is_holding_item(item_id: String) -> bool:
	return selected_item_id == item_id


func get_selected_item_display_name() -> String:
	return String(ITEM_DISPLAY_NAMES.get(selected_item_id, selected_item_id))


func reset_selection() -> void:
	selected_item_index = 0
	selected_item_id = ""
	refresh_selectable_items()
	update_selected_item_visual(false)
	selected_item_changed.emit(selected_item_id)


func _on_inventory_item_changed(_item_id: String, _new_value: int) -> void:
	var previous_selected: String = selected_item_id

	refresh_selectable_items()

	if previous_selected != "" and not BlessingManager.has_item(previous_selected, 1):
		selected_item_index = 0
		selected_item_id = ""

		print("ไอเท็มที่เลือกหมดแล้ว กลับเป็นมือเปล่า")

		update_selected_item_visual(true)
		selected_item_changed.emit(selected_item_id)


func _on_inventory_reset() -> void:
	reset_selection()
