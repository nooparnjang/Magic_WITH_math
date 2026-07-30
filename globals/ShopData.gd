extends Node

# =====================================================
# Shop Database
#
# ใช้เป็น Autoload
#
# เก็บข้อมูล Upgrade ทั้งหมดของเกม
# =====================================================

const ITEMS := {

	# -------------------------------------------------
	# DAMAGE
	# -------------------------------------------------
	"damage": {

		"id": "damage",

		"name": "Damage",

		"description": "Increase Damage by 5%",

		"price": 30,

		"upgrade_type": "damage",

		"upgrade_value": 5.0,

		"is_percent": true,

		"max_level": 10
	},

	# -------------------------------------------------
	# SPEED
	# -------------------------------------------------
	"speed": {

		"id": "speed",

		"name": "Speed",

		"description": "Increase Move Speed by 3%",

		"price": 30,

		"upgrade_type": "speed",

		"upgrade_value": 3.0,

		"is_percent": true,

		"max_level": 10
	},

	# -------------------------------------------------
	# MAX HP
	# -------------------------------------------------
	"max_hp": {

		"id": "max_hp",

		"name": "Max HP",

		"description": "Increase Max HP by 20",

		"price": 50,

		"upgrade_type": "max_hp",

		"upgrade_value": 20.0,

		"is_percent": false,

		"max_level": 5
	},

	# -------------------------------------------------
	# MAX STAMINA
	# -------------------------------------------------
	"max_stamina": {

		"id": "max_stamina",

		"name": "Max Stamina",

		"description": "Increase Max Stamina by 20",

		"price": 50,

		"upgrade_type": "max_stamina",

		"upgrade_value": 20.0,

		"is_percent": false,

		"max_level": 5
	},

	# -------------------------------------------------
	# HEAL RATE
	# -------------------------------------------------
	"heal_rate": {

		"id": "heal_rate",

		"name": "Heal Rate",

		"description": "Increase Heal Rate by 20%",

		"price": 50,

		"upgrade_type": "heal_rate",

		"upgrade_value": 20.0,

		"is_percent": true,

		"max_level": 5
	}

}

# =====================================================
# PUBLIC
# =====================================================

func has_item(item_id:String) -> bool:

	return ITEMS.has(item_id)


func get_item(item_id:String) -> Dictionary:

	return ITEMS.get(item_id, {})


func get_all_items() -> Dictionary:

	return ITEMS


func get_item_ids() -> Array[String]:

	var ids:Array[String] = []

	for id in ITEMS.keys():
		ids.append(id)

	return ids


func get_price(item_id:String) -> int:

	if !ITEMS.has(item_id):
		return 0

	return int(ITEMS[item_id]["price"])


func get_upgrade_value(item_id:String) -> float:

	if !ITEMS.has(item_id):
		return 0.0

	return float(ITEMS[item_id]["upgrade_value"])


func is_percent(item_id:String) -> bool:

	if !ITEMS.has(item_id):
		return false

	return bool(ITEMS[item_id]["is_percent"])


func get_upgrade_type(item_id:String) -> String:

	if !ITEMS.has(item_id):
		return ""

	return String(ITEMS[item_id]["upgrade_type"])


func get_item_name(item_id:String) -> String:

	if !ITEMS.has(item_id):
		return ""

	return String(ITEMS[item_id]["name"])


func get_description(item_id:String) -> String:

	if !ITEMS.has(item_id):
		return ""

	return String(ITEMS[item_id]["description"])


func get_max_level(item_id:String) -> int:

	if !ITEMS.has(item_id):
		return 0

	return int(ITEMS[item_id]["max_level"])

# =====================================================
# DEBUG
# =====================================================

func print_database() -> void:

	print("========== SHOP DATABASE ==========")

	for id in ITEMS.keys():

		var item:Dictionary = ITEMS[id]

		print("-----------------------------------")
		print("ID :", item["id"])
		print("Name :", item["name"])
		print("Price :", item["price"])
		print("Value :", item["upgrade_value"])
		print("Percent :", item["is_percent"])
		print("Max Level :", item["max_level"])
