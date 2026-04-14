extends Node

signal blessings_changed(new_value: int)

var blessings: int = 0

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

func reset_data() -> void:
	blessings = 0
	emit_signal("blessings_changed", blessings)
