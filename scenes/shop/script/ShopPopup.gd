extends CanvasLayer

# =====================================================
# Shop Popup
#
# แสดงข้อความแจ้งเตือนเมื่อซื้อของ
# =====================================================

@export var display_time: float = 1.5

@onready var panel: Control = $Panel
@onready var message: Label = $Panel/Message

var popup_timer: SceneTreeTimer


func _ready() -> void:

	hide_popup()

	if !ShopManager.purchase_success.is_connected(_on_purchase_success):
		ShopManager.purchase_success.connect(_on_purchase_success)

	if !ShopManager.purchase_failed.is_connected(_on_purchase_failed):
		ShopManager.purchase_failed.connect(_on_purchase_failed)


# =====================================================
# Show Popup
# =====================================================

func show_popup(text: String) -> void:

	message.text = text

	visible = true
	panel.visible = true

	if has_node("AnimationPlayer"):
		var animation_player: AnimationPlayer = $AnimationPlayer
		animation_player.play("show")

	popup_timer = get_tree().create_timer(display_time)

	await popup_timer.timeout

	hide_popup()


# =====================================================
# Hide Popup
# =====================================================

func hide_popup() -> void:

	panel.visible = false
	visible = false


# =====================================================
# Purchase Success
# =====================================================

func _on_purchase_success(item_id: String, new_level: int) -> void:

	var item: Dictionary = ShopData.get_item(item_id)

	var item_name: String

	if item.has("name"):
		item_name = String(item["name"])
	else:
		item_name = item_id

	show_popup(
		item_name + " upgraded to Lv." + str(new_level) + "!"
	)


# =====================================================
# Purchase Failed
# =====================================================

func _on_purchase_failed(item_id: String, reason: String) -> void:

	match reason:

		ShopManager.NOT_ENOUGH_BLESSING:
			show_popup("Not Enough Blessings")

		ShopManager.MAX_LEVEL:
			show_popup("Already Max Level")

		ShopManager.INVALID_ITEM:
			show_popup("Invalid Item")

		_:
			show_popup(reason)
