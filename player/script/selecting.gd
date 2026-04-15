extends Sprite2D

@export var show_duration: float = 0.9
@export var fade_duration: float = 0.25

var _hide_tween: Tween = null

func _ready() -> void:
	visible = false
	modulate.a = 1.0

func show_item(new_texture: Texture2D) -> void:
	if new_texture == null:
		hide_item()
		return

	texture = new_texture
	visible = true
	modulate.a = 1.0

	if _hide_tween != null and _hide_tween.is_running():
		_hide_tween.kill()

	_hide_tween = create_tween()
	_hide_tween.tween_interval(show_duration)
	_hide_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	_hide_tween.finished.connect(_on_hide_finished)

func hide_item() -> void:
	if _hide_tween != null and _hide_tween.is_running():
		_hide_tween.kill()

	visible = false
	modulate.a = 1.0
	texture = null

func _on_hide_finished() -> void:
	visible = false
	modulate.a = 1.0
