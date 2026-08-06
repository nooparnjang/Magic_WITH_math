extends CanvasLayer

@export var display_time: float = 1.5

@onready var center_container: Node = $Control
@onready var panel: PanelContainer = $Control/Panel
@onready var message_label: Label = $Control/Panel/Message

var _popup_version: int = 0


func _ready() -> void:
	layer = 100

	if !is_in_group("shop_popup"):
		add_to_group("shop_popup")

	# CanvasLayer ต้องเปิดไว้ตลอด
	visible = true

	# ซ่อนเฉพาะ Container
	center_container.visible = false

	# ป้องกัน Alpha ถูกตั้งเป็น 0
	center_container.modulate = Color.WHITE
	panel.modulate = Color.WHITE
	message_label.modulate = Color.WHITE

	print("ShopPopup ready")
	print("ShopPopup groups: ", get_groups())


func show_success(item_name: String, new_level: int) -> void:
	print(
		"Popup show_success called: ",
		item_name,
		" Lv.",
		new_level
	)

	show_popup(
		"%s upgraded to Lv.%d!" % [
			item_name,
			new_level
		]
	)


func show_failed(reason: String) -> void:
	print("Popup show_failed called: ", reason)

	if reason.is_empty():
		reason = "Purchase Failed"

	show_popup(reason)


func show_popup(text: String) -> void:
	print("Popup show_popup called: ", text)

	if text.is_empty():
		return

	_popup_version += 1
	var current_version: int = _popup_version

	message_label.text = text

	visible = true
	center_container.visible = true
	panel.visible = true
	message_label.visible = true

	center_container.modulate = Color.WHITE
	panel.modulate = Color.WHITE
	message_label.modulate = Color.WHITE

	print("Center visible: ", center_container.visible)
	print("Panel visible: ", panel.visible)
	print("Panel size: ", panel.size)
	print("Panel position: ", panel.global_position)

	await get_tree().create_timer(display_time).timeout

	# Timer เก่าห้ามซ่อน Popup ใหม่
	if current_version != _popup_version:
		return

	center_container.visible = false


func hide_popup() -> void:
	_popup_version += 1
	center_container.visible = false
