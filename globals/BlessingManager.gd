extends Node

signal blessings_changed(new_value: int)
signal item_changed(item_id: String, new_value: int)
signal inventory_reset()

var blessings: int = 0
var items: Dictionary = {}

func set_blessings(value: int) -> void:
	blessings = max(value, 0)
	emit_signal("blessings_changed", blessings)

func add_blessings(amount: int) -> void:
	if amount == 0:
		return

	blessings += amount
	blessings = max(blessings, 0)
	emit_signal("blessings_changed", blessings)

func spend_blessings(amount: int) -> bool:
	if amount <= 0:
		return false

	if blessings < amount:
		return false

	blessings -= amount
	emit_signal("blessings_changed", blessings)
	return true

func get_blessings() -> int:
	return blessings

func set_item_count(item_id: String, value: int) -> void:
	if item_id.is_empty():
		return

	items[item_id] = max(value, 0)

	if items[item_id] <= 0:
		items.erase(item_id)
		emit_signal("item_changed", item_id, 0)
		return

	emit_signal("item_changed", item_id, items[item_id])

func add_item(item_id: String, amount: int = 1) -> void:
	if item_id.is_empty():
		return

	if amount == 0:
		return

	if not items.has(item_id):
		items[item_id] = 0

	items[item_id] += amount
	items[item_id] = max(items[item_id], 0)

	if items[item_id] <= 0:
		items.erase(item_id)
		emit_signal("item_changed", item_id, 0)
		return

	emit_signal("item_changed", item_id, items[item_id])

func spend_item(item_id: String, amount: int = 1) -> bool:
	if item_id.is_empty():
		return false

	if amount <= 0:
		return false

	if not items.has(item_id):
		return false

	if int(items[item_id]) < amount:
		return false

	items[item_id] -= amount
	items[item_id] = max(items[item_id], 0)

	if items[item_id] <= 0:
		items.erase(item_id)
		emit_signal("item_changed", item_id, 0)
	else:
		emit_signal("item_changed", item_id, items[item_id])

	return true

func has_item(item_id: String, amount: int = 1) -> bool:
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

func reset_data() -> void:
	blessings = 0
	items.clear()
	emit_signal("blessings_changed", blessings)
	emit_signal("inventory_reset")
