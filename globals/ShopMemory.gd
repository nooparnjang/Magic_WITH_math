extends Node

# =====================================================
# Signals
# =====================================================

signal upgrade_changed(upgrade_type: String, new_level: int)
signal data_loaded
signal data_saved
signal data_reset

# =====================================================
# Save Path
# =====================================================

const SAVE_PATH := "user://shop_upgrade.json"

# =====================================================
# Upgrade Level Memory
# =====================================================

var _upgrade_levels: Dictionary = {
	"damage": 0,
	"speed": 0,
	"max_hp": 0,
	"max_stamina": 0,
	"heal_rate": 0
}

# =====================================================
# Ready
# =====================================================

func _ready() -> void:
	load_data()

# =====================================================
# Public API
# =====================================================

## คืนค่า Level ของ Upgrade
func get_level(upgrade_type: String) -> int:
	return int(_upgrade_levels.get(upgrade_type, 0))


## คืน Dictionary ทั้งหมด (Copy)
func get_all_levels() -> Dictionary:
	return _upgrade_levels.duplicate(true)


## ตั้งค่า Level โดยตรง
func set_level(upgrade_type: String, level: int) -> void:

	if !_upgrade_levels.has(upgrade_type):
		push_warning("Unknown Upgrade : %s" % upgrade_type)
		return

	level = clamp(level, 0, ShopData.get_max_level(upgrade_type))

	_upgrade_levels[upgrade_type] = level

	save_data()

	upgrade_changed.emit(
		upgrade_type,
		level
	)


## เพิ่ม Level 1 ขั้น
func add_level(upgrade_type: String) -> bool:

	if !_upgrade_levels.has(upgrade_type):
		push_warning("Unknown Upgrade : %s" % upgrade_type)
		return false

	if is_max_level(upgrade_type):
		return false

	_upgrade_levels[upgrade_type] += 1

	save_data()

	upgrade_changed.emit(
		upgrade_type,
		_upgrade_levels[upgrade_type]
	)

	return true


## ลด Level 1 ขั้น
func remove_level(upgrade_type: String) -> bool:

	if !_upgrade_levels.has(upgrade_type):
		return false

	if _upgrade_levels[upgrade_type] <= 0:
		return false

	_upgrade_levels[upgrade_type] -= 1

	save_data()

	upgrade_changed.emit(
		upgrade_type,
		_upgrade_levels[upgrade_type]
	)

	return true


## เช็คว่าเต็มหรือยัง
func is_max_level(upgrade_type: String) -> bool:

	if !_upgrade_levels.has(upgrade_type):
		return true

	return _upgrade_levels[upgrade_type] >= ShopData.get_max_level(upgrade_type)


## รีเซ็ต Upgrade ทั้งหมด
func reset_data() -> void:

	for key in _upgrade_levels.keys():
		_upgrade_levels[key] = 0

	save_data()

	data_reset.emit()

# =====================================================
# Save
# =====================================================

func save_data() -> void:

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("Cannot save ShopMemory")
		return

	file.store_string(
		JSON.stringify(_upgrade_levels, "\t")
	)

	data_saved.emit()

# =====================================================
# Load
# =====================================================

func load_data() -> void:

	if !FileAccess.file_exists(SAVE_PATH):

		save_data()
		return

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("Cannot load ShopMemory")
		return

	var json = JSON.parse_string(
		file.get_as_text()
	)

	if !(json is Dictionary):
		push_error("Invalid ShopMemory Save")
		return

	for key in _upgrade_levels.keys():
		_upgrade_levels[key] = int(
			json.get(key, 0)
		)

	data_loaded.emit()

	for key in _upgrade_levels.keys():

		upgrade_changed.emit(
			key,
			_upgrade_levels[key]
		)

# =====================================================
# Debug
# =====================================================

func print_memory() -> void:

	print("==============================")
	print(" SHOP MEMORY ")
	print("==============================")

	for key in _upgrade_levels.keys():

		print(
			key,
			" Lv.",
			_upgrade_levels[key]
		)
