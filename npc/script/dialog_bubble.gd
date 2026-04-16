extends Control

@export var float_speed := 2.0
@export var float_amount := 2.0

@export var bubble_height := 20.0
@export var horizontal_padding := 10.0
@export var min_bubble_width := 60.0
@export var max_bubble_width := 240.0
@export var typing_speed := 40.0

@onready var bubble_visual: Control = $BubbleVisual
@onready var panel: Panel = $BubbleVisual/Panel
@onready var margin_container: MarginContainer = $BubbleVisual/MarginContainer
@onready var vbox: VBoxContainer = $BubbleVisual/MarginContainer/VBoxContainer
@onready var name_label: Label = $BubbleVisual/MarginContainer/VBoxContainer/name
@onready var text_label: Label = $BubbleVisual/MarginContainer/VBoxContainer/Label

var _float_time := 0.0
var _base_visual_position := Vector2.ZERO

var _lines: Array[String] = []
var _current_line_index := 0
var _current_full_text := ""
var _visible_characters := 0.0
var _is_typing := false
var _dialog_active := false

func _ready() -> void:
	hide()
	await get_tree().process_frame
	_base_visual_position = bubble_visual.position

	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_top", 1)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_bottom", 1)

	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF

func _process(delta: float) -> void:
	if not visible:
		return

	_float_time += delta
	var offset_y := sin(_float_time * float_speed) * float_amount
	bubble_visual.position = _base_visual_position + Vector2(0, offset_y)

	if _is_typing:
		_visible_characters += typing_speed * delta
		var char_count := mini(int(_visible_characters), _current_full_text.length())
		text_label.text = _current_full_text.substr(0, char_count)

		if char_count >= _current_full_text.length():
			_is_typing = false

func show_bubble(npc_name: String, text: String) -> void:
	start_dialog(npc_name, [text])

func start_dialog(npc_name: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return

	show()
	_dialog_active = true
	_float_time = 0.0
	bubble_visual.position = _base_visual_position

	name_label.text = npc_name
	_lines.clear()

	for line in lines:
		_lines.append(String(line))

	_current_line_index = 0
	_show_current_line()

func _show_current_line() -> void:
	if _current_line_index < 0 or _current_line_index >= _lines.size():
		return

	_current_full_text = _lines[_current_line_index]
	_visible_characters = 0.0
	_is_typing = true
	text_label.text = ""

	_resize_bubble_for_text(_current_full_text)

func _resize_bubble_for_text(text: String) -> void:
	var font: Font = text_label.get_theme_font("font")
	var font_size: int = text_label.get_theme_font_size("font_size")

	var text_width := min_bubble_width

	if font != null:
		text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	else:
		text_width = text.length() * 8.0

	var final_width = clamp(text_width + horizontal_padding * 2.0, min_bubble_width, max_bubble_width)

	bubble_visual.custom_minimum_size = Vector2(final_width, bubble_height)
	bubble_visual.size = Vector2(final_width, bubble_height)

	panel.custom_minimum_size = Vector2(final_width, bubble_height)
	panel.size = Vector2(final_width, bubble_height)

	margin_container.custom_minimum_size = Vector2(final_width, bubble_height)
	margin_container.size = Vector2(final_width, bubble_height)

	vbox.custom_minimum_size = Vector2(final_width, bubble_height)
	vbox.size = Vector2(final_width, bubble_height)

func advance_or_finish_line() -> bool:
	if not _dialog_active:
		return false

	if _is_typing:
		text_label.text = _current_full_text
		_is_typing = false
		return false

	_current_line_index += 1

	if _current_line_index >= _lines.size():
		return true

	_show_current_line()
	return false

func hide_bubble() -> void:
	hide()
	_dialog_active = false
	_is_typing = false
	_lines.clear()
	_current_line_index = 0
	_current_full_text = ""
	text_label.text = ""
	bubble_visual.position = _base_visual_position

func is_dialog_active() -> bool:
	return _dialog_active

func is_typing() -> bool:
	return _is_typing
