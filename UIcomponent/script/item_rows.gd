extends HBoxContainer

@export var bomb_texture: Texture2D
@export var scrap_texture: Texture2D
@export var gem_texture: Texture2D
@export var potion_texture: Texture2D
@export var coin_texture: Texture2D
@export var engine_part_texture: Texture2D

@export var icon_size: Vector2 = Vector2(32, 32)

var item_texture_map: Dictionary = {}

func _ready() -> void:
	item_texture_map = {
		"bomb": bomb_texture,
		"scrap": scrap_texture,
		"gem": gem_texture,
		"potion": potion_texture,
		"coin": coin_texture,
		"engine_part": engine_part_texture
	}

	if not BlessingManager.item_changed.is_connected(_on_item_changed):
		BlessingManager.item_changed.connect(_on_item_changed)

	if not BlessingManager.inventory_reset.is_connected(_on_inventory_reset):
		BlessingManager.inventory_reset.connect(_on_inventory_reset)

	redraw_items()

func _on_item_changed(item_id: String, new_value: int) -> void:
	print("UI got:", item_id, new_value)
	redraw_items()

func _on_inventory_reset() -> void:
	redraw_items()

func redraw_items() -> void:
	for child in get_children():
		child.queue_free()

	var all_items: Dictionary = BlessingManager.get_all_items()
	print("all_items =", all_items)

	for item_id in all_items.keys():
		var count: int = int(all_items[item_id])

		if count <= 0:
			continue

		var texture: Texture2D = item_texture_map.get(item_id, null)
		if texture == null:
			print("missing texture:", item_id)
			continue

		for i in range(count):
			var icon := TextureRect.new()
			icon.texture = texture
			icon.custom_minimum_size = icon_size
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			add_child(icon)
			
			start_blink(icon)  

			print("spawn icon for:", item_id)
			
func start_blink(node: Control) -> void:
	var delay := randf_range(0.0, 1.0)

	var tween = create_tween().set_loops()
	tween.tween_interval(delay)

	tween.tween_property(node, "modulate:a", 0.6, 0.5)
	tween.tween_property(node, "modulate:a", 1.0, 0.5)
