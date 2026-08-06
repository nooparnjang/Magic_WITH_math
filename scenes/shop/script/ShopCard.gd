extends Panel

@export var item_id: String = ""

@onready var icon: Panel = $Icon
@onready var description: Label = $Description
@onready var buy_button: TextureButton = $BuyButton
@onready var price: Label = $Price


func _ready() -> void:
	if not ShopData.has_item(item_id):
		push_error(
			"ShopCard: Invalid Item ID -> " + item_id
		)

		if buy_button != null:
			buy_button.disabled = true

		if price != null:
			price.text = "INVALID"

		return

	load_data()

	if not buy_button.pressed.is_connected(_on_buy_pressed):
		buy_button.pressed.connect(_on_buy_pressed)

	if not ShopManager.purchase_success.is_connected(
		_on_purchase_success
	):
		ShopManager.purchase_success.connect(
			_on_purchase_success
		)

	if not ShopManager.purchase_failed.is_connected(
		_on_purchase_failed
	):
		ShopManager.purchase_failed.connect(
			_on_purchase_failed
		)


func load_data() -> void:
	var item: Dictionary = ShopData.get_item(item_id)

	description.text = str(
		item.get("description", "")
	)

	update_ui()


func update_ui() -> void:
	if not ShopData.has_item(item_id):
		return

	var level: int = ShopMemory.get_level(item_id)
	var max_level: int = ShopData.get_max_level(item_id)

	if level >= max_level:
		price.text = "MAX"
		buy_button.disabled = true
		return

	var item_price: int = ShopData.get_price(item_id)

	price.text = str(item_price) + " Blessings"

	# ยังให้กดได้แม้เงินไม่พอ
	# เพื่อให้ Popup แจ้ง Not Enough Blessings
	buy_button.disabled = false


func _on_buy_pressed() -> void:
	if not ShopData.has_item(item_id):
		return

	ShopManager.buy(item_id)


func _on_purchase_success(
	p_item_id: String,
	new_level: int
) -> void:
	if p_item_id != item_id:
		return

	update_ui()

	var popup: Node = get_shop_popup()

	if popup == null:
		return

	var item_name: String = ShopData.get_item_name(item_id)

	if item_name.is_empty():
		item_name = item_id

	popup.show_success(
		item_name,
		new_level
	)


func _on_purchase_failed(
	p_item_id: String,
	reason: String
) -> void:
	if p_item_id != item_id:
		return

	var popup: Node = get_shop_popup()

	if popup == null:
		return

	match reason:
		ShopManager.NOT_ENOUGH_BLESSING:
			popup.show_failed(
				"Not Enough Blessings"
			)

		ShopManager.MAX_LEVEL:
			popup.show_failed(
				"Maximum Level Reached"
			)

		ShopManager.INVALID_ITEM:
			popup.show_failed(
				"Invalid Item"
			)

		_:
			popup.show_failed(
				"Purchase Failed"
			)


func get_shop_popup() -> Node:
	var popup_nodes: Array[Node] = get_tree().get_nodes_in_group(
		"shop_popup"
	)

	for popup_node: Node in popup_nodes:
		if not is_instance_valid(popup_node):
			continue

		if (
			popup_node.has_method("show_success")
			and popup_node.has_method("show_failed")
		):
			return popup_node

	push_warning(
		"ShopCard: shop_popup notification not found"
	)

	return null


func refresh() -> void:
	update_ui()
