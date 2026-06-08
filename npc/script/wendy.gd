extends CharacterBody2D

@export var interact_key: StringName = "ui_talk"

@export_file("*.json")
var dialog_json_path: String = "res://npc/dialog/wendy_dialog.json"

@export var demo_scene: Control

@export var start_state: String = "before_quest"
@export var item_check_state: String = "quest_accepted"
@export var has_item_state: String = "has_item"

@export var idle_animation: StringName = "idle"
@export var talk_animation: StringName = "talk"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hint: Node = $hintE
@onready var bubble: Node = $BubbleAnchor/DialogBubble
@onready var area: Area2D = $Area2D

var player_in_range: bool = false
var current_player: Node2D = null

var is_talking: bool = false
var is_ending_triggered: bool = false

var dialog_data: Dictionary = {}
var npc_name: String = "NPC"

var current_state: String = ""
var required_item: String = ""
var consume_required_item: bool = true

var current_lines: Array = []
var current_line_index: int = 0
var active_bubble: Node = null


func _ready() -> void:
	current_state = start_state

	load_dialog_json()
	setup_demo_scene()
	hide_dialog_ui()

	if area != null:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	else:
		push_error("NPC ไม่มี Area2D สำหรับตรวจจับ player")


func _process(_delta: float) -> void:
	if is_ending_triggered:
		return

	if not player_in_range:
		return

	if Input.is_action_just_pressed(interact_key):
		if not is_talking:
			interact()
		else:
			advance_dialog()


func load_dialog_json() -> void:
	if dialog_json_path.is_empty():
		push_error("dialog_json_path ว่าง")
		return

	if not FileAccess.file_exists(dialog_json_path):
		push_error("ไม่พบไฟล์ JSON: " + dialog_json_path)
		return

	var file := FileAccess.open(dialog_json_path, FileAccess.READ)
	if file == null:
		push_error("เปิดไฟล์ JSON ไม่ได้: " + dialog_json_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON format ผิด ต้องเป็น Dictionary/Object")
		return

	dialog_data = parsed

	npc_name = str(dialog_data.get("npc_name", "NPC"))
	required_item = str(dialog_data.get("required_item", ""))
	consume_required_item = bool(dialog_data.get("consume_required_item", true))

	if not dialog_data.has("states"):
		push_error("JSON ไม่มี key: states")


func setup_demo_scene() -> void:
	if demo_scene == null:
		return

	demo_scene.visible = false
	demo_scene.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func hide_dialog_ui() -> void:
	call_hide_bubble()
	call_hide_hint()


func _on_body_entered(body: Node2D) -> void:
	if is_ending_triggered:
		return

	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		call_show_hint()


func _on_body_exited(body: Node2D) -> void:
	if is_ending_triggered:
		return

	if body == current_player:
		player_in_range = false
		current_player = null
		end_dialog()
		call_hide_hint()


func interact() -> void:
	if is_ending_triggered:
		return

	update_state_by_inventory()

	if current_player != null and current_player.has_method("begin_interaction"):
		current_player.begin_interaction()

	is_talking = true
	call_hide_hint()

	play_animation(talk_animation)
	face_player()

	current_lines = get_current_lines()
	current_line_index = 0

	if current_lines.is_empty():
		push_warning("ไม่มีบทพูดใน state: " + current_state)
		end_dialog()
		return

	show_current_line()


func advance_dialog() -> void:
	if active_bubble == null:
		end_dialog()
		return

	if not active_bubble.has_method("advance_or_finish_line"):
		push_error("DialogBubble ต้องมี method advance_or_finish_line()")
		end_dialog()
		return

	var finished: bool = active_bubble.advance_or_finish_line()

	if finished:
		current_line_index += 1
		show_current_line()


func show_current_line() -> void:
	if current_line_index >= current_lines.size():
		finish_dialog_state()
		end_dialog()
		return

	hide_all_bubbles()

	var line_data = current_lines[current_line_index]

	if typeof(line_data) != TYPE_DICTIONARY:
		push_error("line_data ต้องเป็น Dictionary")
		end_dialog()
		return

	var speaker := str(line_data.get("speaker", npc_name))
	var text := str(line_data.get("text", ""))

	active_bubble = get_bubble_for_speaker(speaker)

	if active_bubble == null:
		push_error("ไม่พบ bubble สำหรับ speaker: " + speaker)
		end_dialog()
		return

	if not active_bubble.has_method("start_dialog"):
		push_error("DialogBubble ต้องมี method start_dialog(npc_name, lines)")
		end_dialog()
		return

	var one_line: Array[String] = []
	one_line.append(text)

	active_bubble.start_dialog(speaker, one_line)

func get_bubble_for_speaker(speaker: String) -> Node:
	if speaker == "Princess Tria":
		if current_player != null and current_player.has_method("get_dialog_bubble"):
			return current_player.get_dialog_bubble()

		push_error("player ไม่มี get_dialog_bubble()")
		return null

	return bubble


func get_current_lines() -> Array:
	var result: Array = []

	var state_data := get_state_data(current_state)

	if state_data.is_empty():
		return result

	var raw_lines = state_data.get("lines", [])

	if typeof(raw_lines) != TYPE_ARRAY:
		push_error("lines ของ state " + current_state + " ต้องเป็น Array")
		return result

	for line in raw_lines:
		if typeof(line) == TYPE_DICTIONARY:
			result.append(line)
		else:
			result.append({
				"speaker": npc_name,
				"text": str(line)
			})

	return result


func update_state_by_inventory() -> void:
	if required_item.is_empty():
		return

	if current_state == has_item_state:
		return

	if current_state == "quest_done":
		return

	if not has_blessing_item(required_item):
		return

	current_state = has_item_state


func finish_dialog_state() -> void:
	var state_data := get_state_data(current_state)

	if state_data.is_empty():
		return

	var should_trigger_ending := bool(state_data.get("trigger_ending", false))

	if should_consume_item_for_state(current_state):
		spend_blessing_item(required_item, 1)

	var next_state := str(state_data.get("next_state", current_state))
	current_state = next_state

	if should_trigger_ending:
		trigger_demo_ending()


func should_consume_item_for_state(state_name: String) -> bool:
	if not consume_required_item:
		return false

	if required_item.is_empty():
		return false

	if state_name != has_item_state:
		return false

	return has_blessing_item(required_item)


func get_state_data(state_name: String) -> Dictionary:
	if not dialog_data.has("states"):
		push_error("dialog_data ไม่มี states")
		return {}

	var states = dialog_data["states"]

	if typeof(states) != TYPE_DICTIONARY:
		push_error("states ต้องเป็น Dictionary/Object")
		return {}

	if not states.has(state_name):
		push_error("ไม่พบ state ใน JSON: " + state_name)
		return {}

	var state_data = states[state_name]

	if typeof(state_data) != TYPE_DICTIONARY:
		push_error("state " + state_name + " ต้องเป็น Dictionary/Object")
		return {}

	return state_data


func end_dialog() -> void:
	is_talking = false
	active_bubble = null

	hide_all_bubbles()

	play_animation(idle_animation)

	if current_player != null and current_player.has_method("end_interaction"):
		current_player.end_interaction()

	if player_in_range and not is_ending_triggered:
		call_show_hint()


func trigger_demo_ending() -> void:
	if is_ending_triggered:
		return

	is_ending_triggered = true
	is_talking = false
	active_bubble = null

	call_hide_hint()
	hide_all_bubbles()

	play_animation(idle_animation)

	if current_player != null and current_player.has_method("end_interaction"):
		current_player.end_interaction()

	if demo_scene != null:
		demo_scene.visible = true
	else:
		push_warning("demo_scene ยังไม่ได้ assign ใน Inspector")

	get_tree().paused = true


func hide_all_bubbles() -> void:
	call_hide_bubble()

	if current_player != null and current_player.has_method("hide_player_bubble"):
		current_player.hide_player_bubble()


func face_player() -> void:
	if current_player == null:
		return

	if sprite == null:
		return

	sprite.flip_h = current_player.global_position.x < global_position.x


func play_animation(animation_name: StringName) -> void:
	if sprite == null:
		return

	if sprite.sprite_frames == null:
		return

	if not sprite.sprite_frames.has_animation(animation_name):
		push_warning("ไม่มี animation: " + str(animation_name))
		return

	if sprite.animation != animation_name:
		sprite.play(animation_name)


func call_show_hint() -> void:
	if hint == null:
		return

	if hint.has_method("show_hint"):
		hint.show_hint()
	else:
		hint.show()


func call_hide_hint() -> void:
	if hint == null:
		return

	if hint.has_method("hide_hint"):
		hint.hide_hint()
	else:
		hint.hide()


func call_hide_bubble() -> void:
	if bubble == null:
		return

	if bubble.has_method("hide_bubble"):
		bubble.hide_bubble()
	else:
		bubble.hide()


func has_blessing_item(item_id: String) -> bool:
	if not is_instance_valid(BlessingManager):
		push_error("ไม่พบ BlessingManager Autoload")
		return false

	if not BlessingManager.has_method("has_item"):
		push_error("BlessingManager ไม่มี method has_item(item_id)")
		return false

	return BlessingManager.has_item(item_id)


func spend_blessing_item(item_id: String, amount: int) -> bool:
	if not is_instance_valid(BlessingManager):
		push_error("ไม่พบ BlessingManager Autoload")
		return false

	if not BlessingManager.has_method("spend_item"):
		push_error("BlessingManager ไม่มี method spend_item(item_id, amount)")
		return false

	return BlessingManager.spend_item(item_id, amount)
