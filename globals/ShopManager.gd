extends Node

# =====================================================
# Shop Manager
#
# ใช้เป็น Autoload
#
# หน้าที่
# - ตรวจสอบ Item
# - ตรวจสอบ Blessing
# - ซื้อ Upgrade
# - เพิ่ม Level
# =====================================================

signal purchase_success(item_id: String, new_level: int)
signal purchase_failed(item_id: String, reason: String)

const SUCCESS := "SUCCESS"
const INVALID_ITEM := "INVALID_ITEM"
const MAX_LEVEL := "MAX_LEVEL"
const NOT_ENOUGH_BLESSING := "NOT_ENOUGH_BLESSING"

# =====================================================
# Purchase
# =====================================================

func buy(item_id: String) -> Dictionary:

	# -------------------------
	# Item Exists ?
	# -------------------------

	if !ShopData.has_item(item_id):

		purchase_failed.emit(
			item_id,
			INVALID_ITEM
		)

		return {
			"success": false,
			"reason": INVALID_ITEM
		}

	# -------------------------
	# Max Level ?
	# -------------------------

	if ShopMemory.is_max_level(item_id):

		purchase_failed.emit(
			item_id,
			MAX_LEVEL
		)

		return {
			"success": false,
			"reason": MAX_LEVEL
		}

	# -------------------------
	# Price
	# -------------------------

	var price: int = ShopData.get_price(item_id)

	# -------------------------
	# Spend Blessing
	# -------------------------

	if !BlessingManager.spend_blessings(price):

		purchase_failed.emit(
			item_id,
			NOT_ENOUGH_BLESSING
		)

		return {
			"success": false,
			"reason": NOT_ENOUGH_BLESSING
		}

	# -------------------------
	# Upgrade
	# -------------------------

	ShopMemory.add_level(item_id)

	var new_level: int = ShopMemory.get_level(item_id)

	purchase_success.emit(
		item_id,
		new_level
	)

	return {
		"success": true,
		"reason": SUCCESS,
		"item_id": item_id,
		"level": new_level
	}

# =====================================================
# Query
# =====================================================

func can_buy(item_id: String) -> bool:

	if !ShopData.has_item(item_id):
		return false

	if ShopMemory.is_max_level(item_id):
		return false

	var price: int = ShopData.get_price(item_id)

	return BlessingManager.get_blessings() >= price


func get_item(item_id: String) -> Dictionary:
	return ShopData.get_item(item_id)


func get_all_items() -> Dictionary:
	return ShopData.get_all_items()


func get_item_ids() -> Array[String]:
	return ShopData.get_item_ids()


func get_price(item_id: String) -> int:
	return ShopData.get_price(item_id)


func get_current_level(item_id: String) -> int:
	return ShopMemory.get_level(item_id)


func get_max_level(item_id: String) -> int:
	return ShopData.get_max_level(item_id)


func get_current_blessing() -> int:
	return BlessingManager.get_blessings()

# =====================================================
# Debug
# =====================================================

func print_shop_status() -> void:

	print("===========================")
	print("SHOP STATUS")
	print("===========================")

	print("Blessing :", BlessingManager.get_blessings())

	for id in ShopData.get_item_ids():

		print(
			id,
			" Lv.",
			ShopMemory.get_level(id),
			"/",
			ShopData.get_max_level(id)
		)
