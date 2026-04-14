extends Sprite2D

@export var required_blessings: int = 25
@export var float_up_distance: float = 200.0
@export var float_duration: float = 0.8

var removed := false

func _ready() -> void:
	if not BlessingManager.blessings_changed.is_connected(_on_blessings_changed):
		BlessingManager.blessings_changed.connect(_on_blessings_changed)

	# กันกรณี blessings ถึงก่อน sprite นี้เกิด
	_try_remove()

func _on_blessings_changed(value: int) -> void:
	_try_remove()

func _try_remove() -> void:
	if removed:
		return

	if BlessingManager.get_blessings() < required_blessings:
		return

	removed = true
	_float_and_remove()

func _float_and_remove() -> void:
	var start_pos := position
	var end_pos := start_pos + Vector2(0, -float_up_distance)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", end_pos, float_duration)
	tween.tween_property(self, "modulate:a", 0.0, float_duration)

	await tween.finished
	queue_free()
