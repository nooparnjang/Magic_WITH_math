extends PanelContainer

enum BubbleType {
	WENDY,
	TRIA,
	ACTION
}

@export var wendy_color: Color = Color(0.25, 0.15, 0.55, 0.88)
@export var tria_color: Color = Color(0.10, 0.22, 0.55, 0.88)
@export var action_color: Color = Color(0.05, 0.05, 0.08, 0.78)

@export var wendy_name_color: Color = Color("#e0b3ff")
@export var tria_name_color: Color = Color("#00e7d3")
@export var action_text_color: Color = Color("#000000")

@export var pop_duration: float = 0.18
@export var fade_duration: float = 0.25

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var text_label: Label = $VBoxContainer/TextLabel
@onready var vbox: VBoxContainer = $VBoxContainer


func setup(bubble_type: String, speaker: String, text: String) -> void:
	text_label.text = text

	match bubble_type:
		"wendy":
			_setup_character_bubble(
				speaker,
				wendy_color,
				HORIZONTAL_ALIGNMENT_RIGHT,
				wendy_name_color
			)

		"tria":
			_setup_character_bubble(
				speaker,
				tria_color,
				HORIZONTAL_ALIGNMENT_LEFT,
				tria_name_color
			)

		"action":
			_setup_action_bubble(action_color)

		_:
			_setup_action_bubble(action_color)


func _setup_character_bubble(
	speaker: String,
	bg_color: Color,
	name_align: HorizontalAlignment,
	name_color: Color
) -> void:
	name_label.visible = true
	name_label.text = speaker
	name_label.horizontal_alignment = name_align
	name_label.add_theme_color_override("font_color", name_color)

	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.add_theme_color_override("font_color", Color.WHITE)

	_set_bg_color(bg_color)


func _setup_action_bubble(bg_color: Color) -> void:
	name_label.visible = false
	name_label.text = ""

	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("font_color", action_text_color)

	_set_bg_color(bg_color)


func _set_bg_color(bg_color: Color) -> void:
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = bg_color
	add_theme_stylebox_override("panel", style)


func play_in() -> void:
	scale = Vector2(0.92, 0.92)
	modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, pop_duration)


func play_out_and_free() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_property(self, "position:y", position.y - 12.0, fade_duration)
	await tween.finished
	queue_free()
