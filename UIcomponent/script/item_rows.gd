extends HBoxContainer

@export var item_icon_scene: PackedScene

@export var bomb_texture: Texture2D
@export var scrap_texture: Texture2D
@export var gem_texture: Texture2D
@export var potion_texture: Texture2D

var item_texture_map: Dictionary = {}

func _ready() -> void:
	item_texture_map = {
		"bomb": bomb_texture,
		"scrap": scrap_texture,
		"gem": gem_texture,
		"potion": potion_texture
	}

	if not BlessingManager.item_changed.is_connected(_on_item_changed):
		BlessingManager.item_changed.connect(_on_item_changed)

	if not BlessingManager.inventory_reset.is_connected(_on_inventory_reset):
		BlessingManager.inventory_reset.connect(_on_inventory_reset)

	redraw_items()

func _on_item_changed(_item_id: String, _new_value: int) -> void:
	redraw_items()

func _on_inventory_reset() -> void:
	redraw_items()

func redraw_items() -> void:
	for child in get_children():
		child.queue_free()

	var all_items := BlessingManager.get_all_items()

	for item_id in all_items.keys():
		var count: int = int(all_items[item_id])

		if count <= 0:
			continue

		var texture: Texture2D = item_texture_map.get(item_id, null)
		if texture == null:
			continue

		for i in range(count):
			var icon_node = item_icon_scene.instantiate()
			add_child(icon_node)

			if icon_node.has_method("set_icon"):
				icon_node.set_icon(texture)
