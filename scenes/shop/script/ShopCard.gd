extends Panel

@export var item_id: String = ""

@onready var icon: Panel = $Icon
@onready var description: Label = $Description
@onready var buy_button: TextureButton = $BuyButton
@onready var price: Label = $Price


func _ready() -> void:

	if !ShopData.has_item(item_id):
		push_error("ShopCard : Invalid Item ID -> " + item_id)
		return

	load_data()

	if !buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.connect(_on_buy_pressed)

	if !ShopManager.purchase_success.is_connected(_on_purchase_success):
		ShopManager.purchase_success.connect(_on_purchase_success)

	if !ShopManager.purchase_failed.is_connected(_on_purchase_failed):
		ShopManager.purchase_failed.connect(_on_purchase_failed)


func load_data() -> void:

	var item: Dictionary = ShopData.get_item(item_id)

	description.text = str(item.get("description", ""))

	update_ui()


func update_ui() -> void:

	var level: int = ShopMemory.get_level(item_id)
	var max_level: int = ShopData.get_max_level(item_id)

	if level >= max_level:

		price.text = "MAX"

		buy_button.disabled = true

	else:

		var item: Dictionary = ShopData.get_item(item_id)

		price.text = str(item.get("price", 0)) + " Blessings"

		buy_button.disabled = false


func _on_buy_pressed() -> void:

	ShopManager.buy(item_id)


func _on_purchase_success(p_item_id: String, new_level: int) -> void:

	if p_item_id != item_id:
		return

	update_ui()

	var popup := get_tree().get_first_node_in_group("shop_popup")

	if popup == null:
		return

	var item: Dictionary = ShopData.get_item(item_id)

	var item_name: String = str(item.get("name", item_id))

	popup.show_success(item_name, new_level)


func _on_purchase_failed(p_item_id: String, reason: String) -> void:

	if p_item_id != item_id:
		return

	var popup := get_tree().get_first_node_in_group("shop_popup")

	if popup == null:
		return

	match reason:

		ShopManager.NOT_ENOUGH_BLESSING:
			popup.show_failed("Not Enough Blessings")

		ShopManager.MAX_LEVEL:
			popup.show_failed("Maximum Level Reached")

		ShopManager.INVALID_ITEM:
			popup.show_failed("Invalid Item")

		_:
			popup.show_failed("Purchase Failed")


func refresh() -> void:
	update_ui()
