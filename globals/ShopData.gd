extends Node

# =====================================================
# Shop Database
#
# เก็บข้อมูล Upgrade ทั้งหมดของร้านค้า
# =====================================================

const ITEMS := {

	"damage": {
		"name": "Increase Damage",
		"description": "Increase Damage by 5%",
		"price": 30,
		"upgrade_value": 5.0,
		"upgrade_type": "percent",
		"max_level": 10
	},

	"speed": {
		"name": "Increase Move Speed",
		"description": "Increase Move Speed by 3%",
		"price": 30,
		"upgrade_value": 3.0,
		"upgrade_type": "percent",
		"max_level": 10
	},

	"max_hp": {
		"name": "Increase Max HP",
		"description": "Increase Max HP by 20",
		"price": 50,
		"upgrade_value": 20.0,
		"upgrade_type": "flat",
		"max_level": 10
	},

	"max_stamina": {
		"name": "Increase Max Stamina",
		"description": "Increase Max Stamina by 15",
		"price": 40,
		"upgrade_value": 15.0,
		"upgrade_type": "flat",
		"max_level": 10
	},

	"heal_rate": {
		"name": "Increase Heal Rate",
		"description": "Increase Heal Rate by 2",
		"price": 45,
		"upgrade_value": 2.0,
		"upgrade_type": "flat",
		"max_level": 10
	}

}


# =====================================================
# Basic
# =====================================================

func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)


func get_item(item_id: String) -> Dictionary:

	if !has_item(item_id):
		return {}

	return ITEMS[item_id]


func get_all_items() -> Dictionary:
	return ITEMS


func get_item_ids() -> Array[String]:

	var ids: Array[String] = []

	for id in ITEMS.keys():
		ids.append(id)

	return ids


# =====================================================
# Individual Getters
# =====================================================

func get_item_name(item_id: String) -> String:

	if !has_item(item_id):
		return ""

	return str(ITEMS[item_id]["name"])


func get_item_description(item_id: String) -> String:

	if !has_item(item_id):
		return ""

	return str(ITEMS[item_id]["description"])


func get_price(item_id: String) -> int:

	if !has_item(item_id):
		return 0

	return int(ITEMS[item_id]["price"])


func get_upgrade_value(item_id: String) -> float:

	if !has_item(item_id):
		return 0.0

	return float(ITEMS[item_id]["upgrade_value"])


func get_upgrade_type(item_id: String) -> String:

	if !has_item(item_id):
		return ""

	return str(ITEMS[item_id]["upgrade_type"])


func is_percent(item_id: String) -> bool:
	return get_upgrade_type(item_id) == "percent"


func get_max_level(item_id: String) -> int:

	if !has_item(item_id):
		return 0

	return int(ITEMS[item_id]["max_level"])


# =====================================================
# Debug
# =====================================================

func print_database() -> void:

	print("========================")
	print("SHOP DATABASE")
	print("========================")

	for id in ITEMS.keys():

		print(
			id,
			" | ",
			get_item_name(id),
			" | Price:",
			get_price(id),
			" | Max Lv:",
			get_max_level(id)
		)
