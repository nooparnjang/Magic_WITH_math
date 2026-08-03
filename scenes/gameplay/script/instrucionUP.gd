extends Sprite2D

@export var breakable_group: StringName = &"breakable_object"
@export var required_destroy_count: int = 2

@export var float_up_distance: float = 300.0
@export var float_duration: float = 0.8

var destroyed_count: int = 0
var removed: bool = false


func _ready() -> void:
	_connect_breakable_objects()


func _connect_breakable_objects() -> void:
	var breakable_objects: Array[Node] = get_tree().get_nodes_in_group(
		breakable_group
	)

	for object: Node in breakable_objects:
		_connect_breakable_object(object)


func _connect_breakable_object(object: Node) -> void:
	if object == self:
		return

	if object.tree_exited.is_connected(_on_breakable_object_removed):
		return

	object.tree_exited.connect(_on_breakable_object_removed)


func _on_breakable_object_removed() -> void:
	if removed:
		return

	destroyed_count += 1

	print(
		"ทำลายของแล้ว: ",
		destroyed_count,
		"/",
		required_destroy_count
	)

	_try_remove()


func _try_remove() -> void:
	if removed:
		return

	if destroyed_count < required_destroy_count:
		return

	removed = true
	_float_and_remove()


func _float_and_remove() -> void:
	var start_pos: Vector2 = position
	var end_pos: Vector2 = start_pos + Vector2.UP * float_up_distance

	var tween: Tween = create_tween()

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"position",
		end_pos,
		float_duration
	)

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		float_duration
	)

	await tween.finished

	queue_free()
