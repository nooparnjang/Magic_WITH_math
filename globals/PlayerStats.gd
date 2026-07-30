extends Node

# =====================================================
# Player Stats Calculator
#
# ใช้เป็น Autoload
#
# หน้าที่
# - อ่านข้อมูลจาก ShopMemory
# - อ่านข้อมูลจาก ShopData
# - คำนวณ Final Stat
#
# ไม่มีการ Save
# ไม่มีการเก็บ Stat
# =====================================================

signal stats_updated

func _ready() -> void:
	if !ShopMemory.upgrade_changed.is_connected(_on_upgrade_changed):
		ShopMemory.upgrade_changed.connect(_on_upgrade_changed)

# =====================================================
# Damage
# =====================================================

func get_final_damage(base_damage: float) -> float:
	return _calculate_stat("damage", base_damage)

# =====================================================
# Speed
# =====================================================

func get_final_speed(base_speed: float) -> float:
	return _calculate_stat("speed", base_speed)

# =====================================================
# Max HP
# =====================================================

func get_final_max_hp(base_hp: float) -> float:
	return _calculate_stat("max_hp", base_hp)

# =====================================================
# Max Stamina
# =====================================================

func get_final_max_stamina(base_stamina: float) -> float:
	return _calculate_stat("max_stamina", base_stamina)

# =====================================================
# Heal Rate
# =====================================================

func get_final_heal_rate(base_heal_rate: float) -> float:
	return _calculate_stat("heal_rate", base_heal_rate)

# =====================================================
# Generic Calculator
# =====================================================

func _calculate_stat(stat_name: String, base_value: float) -> float:

	var level: int = ShopMemory.get_level(stat_name)

	if level <= 0:
		return base_value

	var upgrade_value: float = ShopData.get_upgrade_value(stat_name)

	if ShopData.is_percent(stat_name):
		var percent := (upgrade_value * level) / 100.0
		return base_value * (1.0 + percent)

	return base_value + (upgrade_value * level)

# =====================================================
# Utility
# =====================================================

func get_level(stat_name: String) -> int:
	return ShopMemory.get_level(stat_name)

func is_max_level(stat_name: String) -> bool:
	return ShopMemory.is_max_level(stat_name)

func get_upgrade_value(stat_name: String) -> float:
	return ShopData.get_upgrade_value(stat_name)

func get_upgrade_percent(stat_name: String) -> float:

	if !ShopData.is_percent(stat_name):
		return 0.0

	var level := ShopMemory.get_level(stat_name)

	return ShopData.get_upgrade_value(stat_name) * level

# =====================================================
# Debug
# =====================================================

func print_all() -> void:

	print("==============================")
	print(" Player Stats ")
	print("==============================")

	for id in ShopData.get_item_ids():

		print("------------------------------")
		print("Stat      :", id)
		print("Level     :", ShopMemory.get_level(id))
		print("Value     :", ShopData.get_upgrade_value(id))
		print("Percent   :", ShopData.is_percent(id))

# =====================================================
# Signal
# =====================================================

func _on_upgrade_changed(_type: String, _level: int) -> void:
	stats_updated.emit()
