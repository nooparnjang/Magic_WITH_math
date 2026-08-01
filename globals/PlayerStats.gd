extends Node

signal stats_updated


func _ready() -> void:

	if !ShopMemory.stats_updated.is_connected(_on_shop_updated):
		ShopMemory.stats_updated.connect(_on_shop_updated)


func _on_shop_updated() -> void:
	stats_updated.emit()


# =====================================================
# Final Stats
# =====================================================

func get_final_damage(base_damage: float) -> float:

	return base_damage + (
		ShopMemory.get_level("damage")
		* ShopData.get_upgrade_value("damage")
	)


func get_final_speed(base_speed: float) -> float:

	return base_speed + (
		ShopMemory.get_level("speed")
		* ShopData.get_upgrade_value("speed")
	)


func get_final_max_hp(base_hp: float) -> float:

	return base_hp + (
		ShopMemory.get_level("max_hp")
		* ShopData.get_upgrade_value("max_hp")
	)


func get_final_max_stamina(base_stamina: float) -> float:

	return base_stamina + (
		ShopMemory.get_level("max_stamina")
		* ShopData.get_upgrade_value("max_stamina")
	)


func get_final_heal_rate(base_heal: float) -> float:

	return base_heal + (
		ShopMemory.get_level("heal_rate")
		* ShopData.get_upgrade_value("heal_rate")
	)


# =====================================================
# Debug
# =====================================================

func print_stats() -> void:

	print("====================")
	print("PLAYER STATS")
	print("====================")

	print("Damage Lv :", ShopMemory.get_level("damage"))
	print("Speed Lv :", ShopMemory.get_level("speed"))
	print("Max HP Lv :", ShopMemory.get_level("max_hp"))
	print("Max Stamina Lv :", ShopMemory.get_level("max_stamina"))
	print("Heal Rate Lv :", ShopMemory.get_level("heal_rate"))
