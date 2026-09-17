extends Node

signal blessings_changed(new_value: int)
signal item_changed(item_id: String, new_value: int)
signal inventory_reset()
signal items_reset()

const SAVE_PATH := "user://player_inventory.json"

var blessings: int = 0
var items: Dictionary = {}

# =========================
# Level Reset Settings
# =========================

## 🔄 เปิดไว้ = พอเปลี่ยนฉาก (เปลี่ยนด่าน) ไอเทมจะถูกล้างอัตโนมัติ
var auto_reset_items_on_scene_change: bool = true

## 🎯 รายชื่อฉากที่ "ต้องล้าง" ไอเทมตอนเข้า
## ใส่ได้ทั้ง path เต็ม หรือแค่ชื่อบางส่วนก็ได้ เช่น
##   "res://scenes/gameplay/level2.tscn"  → ตรงตัวเฉพาะฉากนี้
##   "level2"                              → ฉากไหนที่ path มีคำว่า level2
##   "levels/"                             → ทุกฉากในโฟลเดอร์ levels
## ปล่อยว่าง = ล้างทุกครั้งที่เปลี่ยนฉาก
var reset_on_scenes: Array[String] = [
	"res://scenes/gameplay/level1/level_1.tscn",
	"res://scenes/gameplay/level2/level_2_main.tscn",
	"res://scenes/gameplay/level3/level3main.tscn",
	"res://scenes/gameplay/level4/level_4_main.tscn",
	"res://scenes/gameplay/NormalWave.tscn"
]

## 🚫 รายชื่อฉากที่ "ห้ามล้าง" เด็ดขาด (เช็กก่อน reset_on_scenes เสมอ)
## เช่น ฉากร้านค้าหรือห้องพักระหว่างด่าน ที่ไม่อยากให้ไอเทมหาย
var never_reset_scenes: Array[String] = [
	"res://scenes/shop/shop.tscn",
]

var _current_scene_path: String = ""


func _ready() -> void:
	load_data()

	# จำฉากแรกไว้ จะได้ไม่ล้างไอเทมตั้งแต่เปิดเกม
	_current_scene_path = _get_current_scene_path()

	set_process(auto_reset_items_on_scene_change)


func _process(_delta: float) -> void:
	if not auto_reset_items_on_scene_change:
		return

	var path := _get_current_scene_path()

	# ฉากยังโหลดไม่เสร็จ หรือยังเป็นฉากเดิม
	if path.is_empty() or path == _current_scene_path:
		return

	_current_scene_path = path

	if not _should_reset_for_scene(path):
		return

	reset_items()


# 🔎 ฉากนี้ต้องล้างไอเทมไหม
func _should_reset_for_scene(path: String) -> bool:
	# 1) อยู่ในลิสต์ห้ามล้าง -> ไม่ล้าง
	if _path_matches_any(path, never_reset_scenes):
		return false

	# 2) ไม่ได้ระบุฉากไว้เลย -> ล้างทุกฉาก
	if reset_on_scenes.is_empty():
		return true

	# 3) ล้างเฉพาะฉากที่อยู่ในลิสต์
	return _path_matches_any(path, reset_on_scenes)


# เทียบ path กับลิสต์ (ตรงตัวก็ได้ มีคำนั้นอยู่ก็ได้ ไม่สนตัวพิมพ์ใหญ่เล็ก)
func _path_matches_any(path: String, list: Array[String]) -> bool:
	var lower_path := path.to_lower()

	for entry in list:
		if entry.is_empty():
			continue

		if lower_path.contains(entry.to_lower()):
			return true

	return false


func _get_current_scene_path() -> String:
	var tree := get_tree()

	if tree == null:
		return ""

	var scene := tree.current_scene

	if scene == null or not is_instance_valid(scene):
		return ""

	return scene.scene_file_path


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

## 🎒 ล้างเฉพาะไอเทม (บุญ/blessings ยังอยู่เหมือนเดิม)
## ใช้ตอนเปลี่ยนด่าน
func reset_items() -> void:
	if items.is_empty():
		items_reset.emit()
		return

	var old_ids := items.keys().duplicate()

	items.clear()

	# บอก UI ทุกช่องว่าไอเทมหมดแล้ว หลอด/ไอคอนจะได้อัปเดตตาม
	for item_id in old_ids:
		item_changed.emit(str(item_id), 0)

	items_reset.emit()

	save_data()

	print("🎒 เปลี่ยนด่าน: ล้างไอเทมทั้งหมดแล้ว")


## 🔁 เรียกเองตอนกดเปลี่ยนด่าน (ถ้าไม่อยากพึ่งระบบตรวจจับอัตโนมัติ)
func change_level(scene_path: String) -> void:
	reset_items()
	get_tree().change_scene_to_file(scene_path)


## 💥 ล้างทุกอย่าง ทั้งไอเทมและ blessings (ใช้ตอนเริ่มเกมใหม่)
func reset_data() -> void:
	blessings = 0

	var old_ids := items.keys().duplicate()
	items.clear()

	for item_id in old_ids:
		item_changed.emit(str(item_id), 0)

	blessings_changed.emit(blessings)
	items_reset.emit()
	inventory_reset.emit()

	save_data()
