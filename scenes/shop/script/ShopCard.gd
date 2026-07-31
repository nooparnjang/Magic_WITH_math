extends Control

## ==========================================================
## ShopCard.gd
##
## Script นี้ใช้กับ Card ทุกใบในร้าน
##
## Node Structure
##
## ShopCard
## ├── Icon (TextureRect)
## ├── Description (Label)
## ├── BuyButton (Button)
## └── Price (Label)
##
## ==========================================================

@export var item_id : String = ""

@onready var icon : TextureRect = $Icon
@onready var description : Label = $Description
@onready var buy_button : Button = $BuyButton
@onready var price : Label = $Price


func _ready() -> void:

	if item_id == "":
		push_warning(name + " : item_id is empty.")
		return

	if buy_button != null:
		buy_button.pressed.connect(_on_buy_pressed)

	load_data()

	if ShopMemory.has_signal("upgrade_changed"):
		ShopMemory.upgrade_changed.connect(update_ui)

	if BlessingManager.has_signal("blessing_changed"):
		BlessingManager.blessing_changed.connect(update_ui)


func load_data() -> void:

	var data = ShopData.get_item(item_id)

	if data.is_empty():
		push_error("ShopData : " + item_id + " not found.")
		return

	description.text = data["description"]

	price.text = str(data["price"]) + " Blessings"

	if data.has("icon"):
		icon.texture = data["icon"]

	update_ui()


func update_ui() -> void:

	var data = ShopData.get_item(item_id)

	if data.is_empty():
		return

	var level = ShopMemory.get_level(item_id)

	# ---------- MAX LEVEL ----------
	if ShopData.is_max_level(item_id, level):

		price.text = "MAX"

		buy_button.disabled = true

		return

	# ---------- NORMAL ----------
	price.text = str(data["price"]) + " Blessings"

	var enough_money = BlessingManager.get_blessing() >= data["price"]

	buy_button.disabled = !enough_money


func _on_buy_pressed() -> void:

	var success = ShopManager.buy(item_id)

	if success:
		update_ui()
