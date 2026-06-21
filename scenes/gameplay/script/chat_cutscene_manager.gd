extends CanvasLayer

signal cutscene_finished
signal mode_changed(is_auto: bool)

@export var bubble_scene: PackedScene
@export_file("*.json") var chat_json_path: String = ""

@export var interact_key: StringName = "ui_talk"

@export_enum("Manual", "Auto")
var start_mode: String = "Manual"

@export var max_bubbles: int = 3
@export var bubble_spacing: int = 18
@export var auto_start: bool = false

# ใช้ตอน Auto Mode ถ้า JSON ไม่มี delay/lifetime
@export var default_delay_between_bubbles: float = 2.0
@export var default_bubble_lifetime: float = 6.0

@export var use_auto_delay_by_text_length: bool = true
@export var auto_base_delay: float = 1.1
@export var auto_char_delay: float = 0.035
@export var auto_min_delay: float = 1.6
@export var auto_max_delay: float = 3.5

@export var input_cooldown: float = 0.12

@export var clear_bubbles_on_finish: bool = true
@export var change_scene_when_finished: bool = true

@export_file("*.tscn")
var next_scene_path: String = ""

@onready var bubble_stack: VBoxContainer = $BubbleStack
@onready var autoplay_button: Button = $HBoxContainer/autoplay
@onready var skip_button: Button = $HBoxContainer/skip

var is_playing: bool = false
var is_finished: bool = false
var is_auto_mode: bool = false
var auto_loop_running: bool = false
var is_changing_scene: bool = false

var chat_data: Array = []
var current_index: int = 0
var active_bubbles: Array[Control] = []

var can_press_next: bool = true


func _ready() -> void:
	visible = false

	if bubble_stack != null:
		bubble_stack.add_theme_constant_override("separation", bubble_spacing)

	if autoplay_button != null:
		if not autoplay_button.pressed.is_connected(_on_autoplay_pressed):
			autoplay_button.pressed.connect(_on_autoplay_pressed)

	if skip_button != null:
		if not skip_button.pressed.is_connected(_on_skip_pressed):
			skip_button.pressed.connect(_on_skip_pressed)

	is_auto_mode = start_mode == "Auto"
	_update_autoplay_button_text()

	if auto_start:
		start_chat()


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return

	if is_auto_mode:
		return

	if not can_press_next:
		return

	if event.is_action_pressed(interact_key):
		get_viewport().set_input_as_handled()
		_next_bubble_manual()


func start_chat() -> void:
	if is_playing:
		return

	if bubble_scene == null:
		push_error("ChatCutsceneManager: bubble_scene is not assigned.")
		return

	chat_data = _load_chat_json(chat_json_path)

	if chat_data.is_empty():
		push_error("ChatCutsceneManager: chat json is empty or invalid.")
		return

	is_playing = true
	is_finished = false
	auto_loop_running = false
	is_changing_scene = false
	current_index = 0
	visible = true

	if is_auto_mode:
		_start_auto_loop()
	else:
		_next_bubble_manual()


func _on_autoplay_pressed() -> void:
	toggle_auto_mode()


func _on_skip_pressed() -> void:
	# กดแล้วข้ามทันที เปลี่ยนซีนเลย
	skip_cutscene()


func skip_cutscene() -> void:
	if is_changing_scene:
		return

	is_finished = true
	is_playing = false
	auto_loop_running = false

	clear_all_bubbles()
	cutscene_finished.emit()

	_change_to_next_scene()


func set_auto_mode(enabled: bool) -> void:
	is_auto_mode = enabled
	mode_changed.emit(is_auto_mode)
	_update_autoplay_button_text()

	if not is_playing:
		return

	if is_auto_mode:
		_start_auto_loop()


func toggle_auto_mode() -> void:
	set_auto_mode(not is_auto_mode)


func _update_autoplay_button_text() -> void:
	if autoplay_button == null:
		return

	if is_auto_mode:
		autoplay_button.text = "STOP AUTO"
	else:
		autoplay_button.text = "AUTOPLAY"

func _start_auto_loop() -> void:
	if auto_loop_running:
		return

	auto_loop_running = true
	_auto_loop()


func _auto_loop() -> void:
	while is_playing and is_auto_mode:
		if current_index >= chat_data.size():
			_finish_chat()
			break

		var entry: Dictionary = _get_entry_at_index(current_index)
		var text: String = str(entry.get("text", ""))

		_spawn_next_bubble()

		if not is_playing:
			break

		var wait_time: float = _get_wait_time_for_entry(entry, text)
		await get_tree().create_timer(wait_time).timeout

	auto_loop_running = false


func _next_bubble_manual() -> void:
	if is_finished:
		return

	if not can_press_next:
		return

	can_press_next = false
	_start_input_cooldown()

	if current_index >= chat_data.size():
		_finish_chat()
		return

	_spawn_next_bubble()


func _start_input_cooldown() -> void:
	await get_tree().create_timer(input_cooldown).timeout
	can_press_next = true


func _spawn_next_bubble() -> void:
	if current_index >= chat_data.size():
		return

	var entry_variant: Variant = chat_data[current_index]
	current_index += 1

	if typeof(entry_variant) != TYPE_DICTIONARY:
		_spawn_next_bubble()
		return

	var entry: Dictionary = entry_variant as Dictionary

	var bubble_type: String = str(entry.get("type", "action"))
	var speaker: String = str(entry.get("speaker", ""))
	var text: String = str(entry.get("text", ""))

	if text.is_empty():
		_spawn_next_bubble()
		return

	var lifetime: float = float(entry.get("lifetime", default_bubble_lifetime))
	_spawn_bubble(bubble_type, speaker, text, lifetime)


func _get_entry_at_index(index: int) -> Dictionary:
	if index < 0 or index >= chat_data.size():
		return {}

	var entry_variant: Variant = chat_data[index]

	if typeof(entry_variant) != TYPE_DICTIONARY:
		return {}

	return entry_variant as Dictionary


func _get_wait_time_for_entry(entry: Dictionary, text: String) -> float:
	if entry.has("delay"):
		return float(entry.get("delay", default_delay_between_bubbles))

	if use_auto_delay_by_text_length:
		var result: float = auto_base_delay + float(text.length()) * auto_char_delay
		return clamp(result, auto_min_delay, auto_max_delay)

	return default_delay_between_bubbles


func _load_chat_json(path: String) -> Array:
	if path.is_empty():
		push_error("ChatCutsceneManager: chat_json_path is empty.")
		return []

	if not FileAccess.file_exists(path):
		push_error("ChatCutsceneManager: file does not exist: " + path)
		return []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("ChatCutsceneManager: cannot open file: " + path)
		return []

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)

	if typeof(parsed) != TYPE_ARRAY:
		push_error("ChatCutsceneManager: JSON root must be an Array.")
		return []

	return parsed as Array


func _spawn_bubble(bubble_type: String, speaker: String, text: String, lifetime: float) -> void:
	if bubble_stack == null:
		push_error("ChatCutsceneManager: BubbleStack node not found.")
		return

	var bubble: Control = bubble_scene.instantiate() as Control

	if bubble == null:
		push_error("ChatCutsceneManager: bubble_scene root must be Control.")
		return

	bubble_stack.add_child(bubble)

	if bubble.has_method("setup"):
		bubble.setup(bubble_type, speaker, text)

	active_bubbles.append(bubble)

	if bubble.has_method("play_in"):
		bubble.play_in()

	if active_bubbles.size() > max_bubbles:
		var oldest: Control = active_bubbles.pop_front()

		if is_instance_valid(oldest):
			if oldest.has_method("play_out_and_free"):
				oldest.play_out_and_free()
			else:
				oldest.queue_free()

	if is_auto_mode:
		_auto_remove_bubble_after_lifetime(bubble, lifetime)


func _auto_remove_bubble_after_lifetime(bubble: Control, lifetime: float) -> void:
	await get_tree().create_timer(lifetime).timeout

	if not is_instance_valid(bubble):
		return

	active_bubbles.erase(bubble)

	if bubble.has_method("play_out_and_free"):
		bubble.play_out_and_free()
	else:
		bubble.queue_free()


func _finish_chat() -> void:
	if is_finished:
		return

	is_finished = true
	is_playing = false
	auto_loop_running = false

	if clear_bubbles_on_finish:
		clear_all_bubbles()

	cutscene_finished.emit()

	if change_scene_when_finished:
		_change_to_next_scene()


func _change_to_next_scene() -> void:
	if is_changing_scene:
		return

	is_changing_scene = true

	if next_scene_path.is_empty():
		push_error("ChatCutsceneManager: next_scene_path is empty.")
		return

	var error: Error = get_tree().change_scene_to_file(next_scene_path)

	if error != OK:
		push_error("ChatCutsceneManager: failed to change scene to: " + next_scene_path)


func clear_all_bubbles() -> void:
	for bubble: Control in active_bubbles:
		if is_instance_valid(bubble):
			if bubble.has_method("play_out_and_free"):
				bubble.play_out_and_free()
			else:
				bubble.queue_free()

	active_bubbles.clear()
	
	
