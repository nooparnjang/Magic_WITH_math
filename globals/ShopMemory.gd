extends Node

# =====================================================
# Shop Memory
#
# หน้าที่
# - จำว่า Player ซื้อ Upgrade อะไรไปแล้ว
# - เก็บ Level ของ Upgrade
# - ส่ง Signal เมื่อมีการเปลี่ยนแปลง
# =====================================================

signal stats_updated

# =====================================================
# Upgrade Levels
# =====================================================

var levels: Dictionary = {
	"damage": 0,
	"speed": 0,
	"max_hp": 0,
	"max_stamina": 0,
	"heal_rate": 0
}


# =====================================================
# Get
# =====================================================

func get_level(item_id: String) -> int:

	if !levels.has(item_id):
		return 0

	return levels[item_id]


func get_all_levels() -> Dictionary:
	return levels.duplicate(true)


# =====================================================
# Set
# =====================================================

func set_level(item_id: String, level: int) -> void:

	if !levels.has(item_id):
		push_error("ShopMemory : Invalid Item ID -> " + item_id)
		return

	var max_level: int = ShopData.get_max_level(item_id)

	level = clamp(level, 0, max_level)

	levels[item_id] = level

	stats_updated.emit()


# =====================================================
# Add
# =====================================================

func add_level(item_id: String) -> void:

	if !levels.has(item_id):
		push_error("ShopMemory : Invalid Item ID -> " + item_id)
		return

	var current: int = levels[item_id]
	var max_level: int = ShopData.get_max_level(item_id)

	if current >= max_level:
		return

	levels[item_id] += 1

	stats_updated.emit()


# =====================================================
# Check
# =====================================================

func is_max_level(item_id: String) -> bool:

	if !levels.has(item_id):
		return true

	return levels[item_id] >= ShopData.get_max_level(item_id)


func has_upgrade(item_id: String) -> bool:

	if !levels.has(item_id):
		return false

	return levels[item_id] > 0


# =====================================================
# Reset
# =====================================================

func reset() -> void:

	for id in levels.keys():
		levels[id] = 0

	stats_updated.emit()


# =====================================================
# Debug
# =====================================================

func print_levels() -> void:

	print("==========================")
	print("SHOP MEMORY")
	print("==========================")

	for id in levels.keys():

		print(
			id,
			" : Lv.",
			levels[id],
			"/",
			ShopData.get_max_level(id)
		)
