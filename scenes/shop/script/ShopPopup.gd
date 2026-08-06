extends CanvasLayer

@export var display_time: float = 1.5

@onready var center_container: Control = $Control
@onready var panel: PanelContainer = $Control/Panel
@onready var message_label: Label = $Control/Panel/Message

var _popup_version: int = 0


func _ready() -> void:
	# ร้านใช้ layer 100 ดังนั้นข้อความต้องสูงกว่า
	layer = 200

	# ต้องทำงานตอนเกม pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not is_in_group("shop_popup"):
		add_to_group("shop_popup")

	visible = true
	center_container.visible = false

	reset_visual_state()

	print(
		"Shop notification ready: ",
		get_path()
	)


func show_success(
	item_name: String,
	new_level: int
) -> void:
	show_popup(
		"%s upgraded to Lv.%d!" % [
			item_name,
			new_level
		]
	)


func show_failed(reason: String) -> void:
	if reason.is_empty():
		reason = "Purchase Failed"

	show_popup(reason)


func show_popup(text: String) -> void:
	if text.is_empty():
		return

	_popup_version += 1
	var current_version: int = _popup_version

	message_label.text = text

	visible = true
	center_container.visible = true
	panel.visible = true
	message_label.visible = true

	reset_visual_state()

	print(
		"Showing shop popup: ",
		text,
		" | paused: ",
		get_tree().paused,
		" | path: ",
		get_path()
	)

	await get_tree().create_timer(
		display_time,
		true
	).timeout

	if current_version != _popup_version:
		return

	center_container.visible = false


func hide_popup() -> void:
	_popup_version += 1
	center_container.visible = false


func reset_visual_state() -> void:
	center_container.modulate = Color.WHITE
	panel.modulate = Color.WHITE
	message_label.modulate = Color.WHITE
