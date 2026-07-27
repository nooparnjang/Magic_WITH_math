extends Node

signal blessings_changed(new_value: int)
signal item_changed(item_id: String, new_value: int)
signal inventory_reset()

const SAVE_PATH := "user://player_inventory.json"

var blessings: int = 0
var items: Dictionary = {}


func _ready() -> void:
	load_data()


# =========================
# Blessings
# =========================

func set_blessings(value: int) -> void:
	blessings = max(value, 0)

	blessings_changed.emit(blessings)

	save_data()


func add_blessings(amount: int) -> void:
	if amount == 0:
		return

	blessings += amount
	blessings = max(blessings, 0)

	blessings_changed.emit(blessings)

	save_data()


func spend_blessings(amount: int) -> bool:
	if amount <= 0:
		return false

	if blessings < amount:
		return false

	blessings -= amount

	blessings_changed.emit(blessings)

	save_data()

	return true


func get_blessings() -> int:
	return blessings


# =========================
# Items
# =========================

func set_item_count(item_id: String, value: int) -> void:
	if item_id.is_empty():
		return

	items[item_id] = max(value, 0)

	if int(items[item_id]) <= 0:
		items.erase(item_id)
		item_changed.emit(item_id, 0)
	else:
		item_changed.emit(
			item_id,
			int(items[item_id])
		)

	save_data()


func add_item(
	item_id: String,
	amount: int = 1
) -> void:

	if item_id.is_empty():
		return

	if amount == 0:
		return

	if not items.has(item_id):
		items[item_id] = 0

	items[item_id] += amount
	items[item_id] = max(
		int(items[item_id]),
		0
	)

	if int(items[item_id]) <= 0:
		items.erase(item_id)
		item_changed.emit(item_id, 0)
	else:
		item_changed.emit(
			item_id,
			int(items[item_id])
		)

	save_data()


func spend_item(
	item_id: String,
	amount: int = 1
) -> bool:

	if item_id.is_empty():
		return false

	if amount <= 0:
		return false

	if not items.has(item_id):
		return false

	if int(items[item_id]) < amount:
		return false

	items[item_id] -= amount

	if int(items[item_id]) <= 0:
		items.erase(item_id)
		item_changed.emit(item_id, 0)
	else:
		item_changed.emit(
			item_id,
			int(items[item_id])
		)

	save_data()

	return true


func has_item(
	item_id: String,
	amount: int = 1
) -> bool:

	if item_id.is_empty():
		return false

	if amount <= 0:
		return true

	if not items.has(item_id):
		return false

	return int(items[item_id]) >= amount


func get_item_count(item_id: String) -> int:
	if item_id.is_empty():
		return 0

	if not items.has(item_id):
		return 0

	return int(items[item_id])


func get_total_items() -> int:
	var total := 0

	for key in items.keys():
		total += int(items[key])

	return total


func get_all_items() -> Dictionary:
	return items.duplicate(true)


# =========================
# SAVE / LOAD
# =========================

func save_data() -> void:
	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"Could not save player inventory."
		)
		return

	var data := {
		"blessings": blessings,
		"items": items
	}

	file.store_string(
		JSON.stringify(data, "\t")
	)


func load_data() -> void:
	if not FileAccess.file_exists(
		SAVE_PATH
	):
		return

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"Could not load player inventory."
		)
		return

	var data = JSON.parse_string(
		file.get_as_text()
	)

	if not data is Dictionary:
		push_error(
			"Invalid inventory save file."
		)
		return

	blessings = int(
		data.get("blessings", 0)
	)

	var loaded_items = data.get(
		"items",
		{}
	)

	if loaded_items is Dictionary:
		items = loaded_items.duplicate(true)
	else:
		items = {}

	blessings_changed.emit(blessings)

	for item_id in items.keys():
		item_changed.emit(
			str(item_id),
			int(items[item_id])
		)


# =========================
# Reset
# =========================

func reset_data() -> void:
	blessings = 0
	items.clear()

	blessings_changed.emit(blessings)
	inventory_reset.emit()

	save_data()
