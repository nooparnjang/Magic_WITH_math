extends CanvasLayer

# =====================================================
# Shop Popup
#
# หน้าที่
# - แสดงข้อความซื้อสำเร็จ
# - แสดงข้อความซื้อไม่สำเร็จ
# - แสดง Popup พร้อม Animation เด้งดึ๋ง
# - ทำงานได้แม้เกม Pause
# =====================================================


# =====================================================
# Settings
# =====================================================

@export var display_time: float = 1.5

# ความเร็ว Animation
@export var animation_time: float = 0.35


# =====================================================
# Nodes
# =====================================================

@onready var center_container: Control = $Control
@onready var panel: PanelContainer = $Control/Panel
@onready var message_label: Label = $Control/Panel/Message


# =====================================================
# Variables
# =====================================================

var _popup_version: int = 0
var _panel_tween: Tween


# =====================================================
# Ready
# =====================================================

func _ready() -> void:

	# ร้านใช้ Layer 100
	# Popup ต้องอยู่ด้านบนกว่า
	layer = 200

	# ต้องทำงานแม้เกม Pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	# เพิ่มเข้า Group เพื่อให้ ShopCard หา Popup ได้
	if not is_in_group("shop_popup"):
		add_to_group("shop_popup")

	# เริ่มต้นให้ Popup ซ่อน
	visible = true
	center_container.visible = false
	panel.visible = false
	message_label.visible = false

	# ตั้ง Pivot ให้อยู่ตรงกลาง Panel
	panel.pivot_offset = panel.size / 2.0

	reset_visual_state()

	print(
		"Shop notification ready: ",
		get_path()
	)


# =====================================================
# Show Success
# =====================================================

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


# =====================================================
# Show Failed
# =====================================================

func show_failed(reason: String) -> void:

	if reason.is_empty():
		reason = "Purchase Failed"

	show_popup(reason)


# =====================================================
# Show Popup
# =====================================================

func show_popup(text: String) -> void:

	if text.is_empty():
		return

	# เพิ่ม Version
	# ใช้ป้องกัน Popup เก่ามาซ่อน Popup ใหม่
	_popup_version += 1

	var current_version: int = _popup_version

	# ตั้งข้อความ
	message_label.text = text

	# เปิด Popup
	visible = true
	center_container.visible = true
	panel.visible = true
	message_label.visible = true

	# อัปเดต Pivot หลังจาก Panel มีขนาดแล้ว
	panel.pivot_offset = panel.size / 2.0

	# Reset ก่อนเริ่ม Animation
	reset_visual_state()

	# เริ่ม Animation
	_play_popup_animation()

	print(
		"Showing shop popup: ",
		text,
		" | paused: ",
		get_tree().paused,
		" | path: ",
		get_path()
	)

	# รอเวลาที่กำหนด
	await get_tree().create_timer(
		display_time,
		true
	).timeout

	# ถ้ามี Popup ใหม่เข้ามาแล้ว
	# Popup เก่าจะไม่สั่งซ่อน
	if current_version != _popup_version:
		return

	hide_popup()


# =====================================================
# Popup Animation
# =====================================================

func _play_popup_animation() -> void:

	# ยกเลิก Tween เดิม
	_kill_panel_tween()

	# เริ่มต้นให้เล็กกว่าปกติ
	panel.scale = Vector2(0.65, 0.65)

	# ทำ Tween ใหม่
	_panel_tween = create_tween()

	# ให้ Tween ทำงานแม้เกม Pause
	_panel_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# -------------------------------------------------
	# เด้งขึ้นมา
	# -------------------------------------------------

	_panel_tween.tween_property(
		panel,
		"scale",
		Vector2(1.12, 1.12),
		animation_time * 0.55
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# -------------------------------------------------
	# เด้งกลับลงมาเล็กน้อย
	# -------------------------------------------------

	_panel_tween.tween_property(
		panel,
		"scale",
		Vector2(0.94, 0.94),
		animation_time * 0.25
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# -------------------------------------------------
	# กลับสู่ขนาดปกติ
	# -------------------------------------------------

	_panel_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		animation_time * 0.20
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# =====================================================
# Kill Existing Tween
# =====================================================

func _kill_panel_tween() -> void:

	if _panel_tween != null:
		_panel_tween.kill()
		_panel_tween = null


# =====================================================
# Hide Popup
# =====================================================

func hide_popup() -> void:

	_popup_version += 1

	_kill_panel_tween()

	center_container.visible = false
	panel.visible = false
	message_label.visible = false


# =====================================================
# Reset Visual State
# =====================================================

func reset_visual_state() -> void:

	center_container.modulate = Color.WHITE
	panel.modulate = Color.WHITE
	message_label.modulate = Color.WHITE

	# Popup กลับสู่ขนาดปกติ
	panel.scale = Vector2.ONE
