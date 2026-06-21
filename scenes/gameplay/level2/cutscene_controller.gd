extends Node

@export_file("*.json")
var cutscene_json_path: String = "res://cutscenes/json/wendy_to_factory_cutscene.json"

@export var auto_start: bool = true
@export var advance_action: StringName = &"ui_talk"

@export_group("Actors - CharacterBody2D")
@export var tria_body: CharacterBody2D
@export var wendy_body: CharacterBody2D

@export_group("Actor Sprites")
@export var tria_sprite: AnimatedSprite2D
@export var wendy_sprite: AnimatedSprite2D

@export_group("Dialog Bubbles - Assign Directly")
@export var tria_dialog_bubble: Node
@export var wendy_dialog_bubble: Node

@export_group("Camera")
@export var camera_2d: Camera2D
@export var default_camera_zoom: float = 1.0
@export var camera_transition_time: float = 0.45

# ใช้เลื่อน CameraTwoShot ลงโดยไม่ต้องขยับ Marker
# ค่า y มากขึ้น = กล้องลงล่างใน Godot 2D
@export var camera_two_shot_offset: Vector2 = Vector2(0, 45)

@export_group("Actor Markers")
@export var tria_start: Node2D
@export var tria_talk_point: Node2D
@export var wendy_point: Node2D

@export_group("Camera Markers")
@export var camera_wide: Node2D
@export var camera_tria: Node2D
@export var camera_wendy: Node2D
@export var camera_two_shot: Node2D

@export_group("Fade")
@export var fade_rect: ColorRect

@export_group("Animation Names")
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"walk"
@export var talk_animation: StringName = &"talk"

var cutscene_data: Dictionary = {}
var is_playing: bool = false

var waiting_for_dialog_input: bool = false
var active_dialog_bubble: Node = null
var active_speaker_body: CharacterBody2D = null

var saved_actor_states: Dictionary = {}


func _ready() -> void:
	if fade_rect != null:
		fade_rect.visible = true
		fade_rect.color.a = 1.0

	if auto_start:
		call_deferred("start_cutscene")


func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return

	if not waiting_for_dialog_input:
		return

	if event.is_action_pressed(advance_action):
		advance_dialog_input()
		get_viewport().set_input_as_handled()


func start_cutscene(path: String = "") -> void:
	if is_playing:
		return

	if path != "":
		cutscene_json_path = path

	is_playing = true

	load_cutscene_json()

	if cutscene_data.is_empty():
		push_error("Cutscene JSON โหลดไม่ได้")
		is_playing = false
		return

	await prepare_cutscene()
	await run_steps()

	is_playing = false


func load_cutscene_json() -> void:
	cutscene_data.clear()

	if cutscene_json_path.is_empty():
		push_error("cutscene_json_path ว่าง")
		return

	if not FileAccess.file_exists(cutscene_json_path):
		push_error("ไม่พบไฟล์ cutscene JSON: " + cutscene_json_path)
		return

	var file := FileAccess.open(cutscene_json_path, FileAccess.READ)
	if file == null:
		push_error("เปิดไฟล์ cutscene JSON ไม่ได้: " + cutscene_json_path)
		return

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Cutscene JSON ต้องเป็น Object / Dictionary")
		return

	cutscene_data = parsed


func prepare_cutscene() -> void:
	hide_all_dialogs()

	lock_actor(tria_body)
	lock_actor(wendy_body)

	if camera_2d != null:
		camera_2d.make_current()
	else:
		push_warning("camera_2d ยังไม่ได้ assign")

	await get_tree().process_frame


func run_steps() -> void:
	var steps = cutscene_data.get("steps", [])

	if typeof(steps) != TYPE_ARRAY:
		push_error("JSON key steps ต้องเป็น Array")
		return

	for raw_step in steps:
		if typeof(raw_step) != TYPE_DICTIONARY:
			push_warning("ข้าม step เพราะไม่ใช่ Dictionary")
			continue

		await run_step(raw_step)


func run_step(step: Dictionary) -> void:
	var step_type := str(step.get("type", ""))

	match step_type:
		"setup_actor":
			run_setup_actor(step)

		"actor_anim":
			run_actor_anim(step)

		"wait_anim":
			await run_wait_anim(step)

		"actor_flip":
			run_actor_flip(step)

		"move_actor":
			await run_move_actor(step)

		"turn_actor":
			await run_turn_actor(step)

		"camera":
			await run_camera(step)

		"dialog":
			await run_dialog(step)

		"wait":
			await run_wait(step)

		"fade_in":
			await run_fade(step, false)

		"fade_out":
			await run_fade(step, true)

		"change_scene":
			run_change_scene()

		"finish":
			finish_cutscene_without_scene_change()

		_:
			push_warning("ไม่รู้จัก cutscene step type: " + step_type)


func run_setup_actor(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var marker_id := str(step.get("marker", ""))
	var animation_name := StringName(str(step.get("animation", "")))

	var actor := get_actor_body(actor_id)

	if actor == null:
		push_warning("setup_actor: ไม่พบ actor " + actor_id)
		return

	# ถ้า marker_id ว่าง จะไม่ย้าย actor
	# ใช้กับ Wendy ได้ ถ้าไม่อยากให้ Wendy ถูก teleport ตกแมพ
	if marker_id != "":
		var marker := get_marker(marker_id)

		if marker != null:
			teleport_actor(actor, marker.global_position)
		else:
			push_warning("setup_actor: ไม่พบ marker " + marker_id + " จะไม่ย้ายตำแหน่ง actor")

	if step.has("flip_h"):
		set_actor_flip(actor, bool(step.get("flip_h")))

	if animation_name != &"":
		play_actor_animation(actor, animation_name)


func run_actor_anim(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var animation_name := StringName(str(step.get("animation", "")))

	var actor := get_actor_body(actor_id)

	if actor == null:
		push_warning("actor_anim: ไม่พบ actor " + actor_id)
		return

	play_actor_animation(actor, animation_name)


func run_wait_anim(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var animation_name := StringName(str(step.get("animation", "")))
	var fallback_delay := float(step.get("fallback_delay", 0.25))

	var actor := get_actor_body(actor_id)

	if actor == null:
		push_warning("wait_anim: ไม่พบ actor " + actor_id)
		return

	await play_actor_animation_and_wait(actor, animation_name, fallback_delay)


func run_actor_flip(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var flip_h := bool(step.get("flip_h", false))

	var actor := get_actor_body(actor_id)

	if actor == null:
		push_warning("actor_flip: ไม่พบ actor " + actor_id)
		return

	set_actor_flip(actor, flip_h)


func run_move_actor(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var marker_id := str(step.get("marker", ""))
	var duration := float(step.get("duration", 1.0))
	var animation_name := StringName(str(step.get("animation", str(walk_animation))))

	var actor := get_actor_body(actor_id)
	var marker := get_marker(marker_id)

	if actor == null:
		push_warning("move_actor: ไม่พบ actor " + actor_id)
		return

	if marker == null:
		push_warning("move_actor: ไม่พบ marker " + marker_id)
		return

	face_position(actor, marker.global_position)
	play_actor_animation(actor, animation_name)

	if duration <= 0.0:
		teleport_actor(actor, marker.global_position)
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(actor, "global_position", marker.global_position, duration)

	await tween.finished

	actor.velocity = Vector2.ZERO


func run_turn_actor(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var face_actor_id := str(step.get("face_actor", ""))
	var turn_animation := StringName(str(step.get("turn_animation", "")))
	var fallback_delay := float(step.get("fallback_delay", 0.3))

	var actor := get_actor_body(actor_id)
	var target_actor := get_actor_body(face_actor_id)

	if actor == null:
		push_warning("turn_actor: ไม่พบ actor " + actor_id)
		return

	if target_actor == null:
		push_warning("turn_actor: ไม่พบ face_actor " + face_actor_id)
		return

	if turn_animation != &"":
		await play_actor_animation_and_wait(actor, turn_animation, fallback_delay)
	else:
		await get_tree().create_timer(fallback_delay).timeout

	face_position(actor, target_actor.global_position)
	play_actor_animation(actor, idle_animation)


func run_camera(step: Dictionary) -> void:
	if camera_2d == null:
		push_warning("camera_2d ยังไม่ได้ assign")
		return

	var marker_id := str(step.get("marker", ""))
	var zoom_value := float(step.get("zoom", default_camera_zoom))
	var duration := float(step.get("duration", camera_transition_time))

	var marker := get_marker(marker_id)

	if marker == null:
		push_warning("camera: ไม่พบ marker " + marker_id)
		return

	var target_position := marker.global_position

	# เลื่อน CameraTwoShot ลงอัตโนมัติ
	if marker_id == "camera_two_shot":
		target_position += camera_two_shot_offset

	# รองรับ offset เพิ่มใน JSON เช่น "camera_offset": [0, 30]
	if step.has("camera_offset"):
		var raw_offset = step.get("camera_offset")

		if typeof(raw_offset) == TYPE_ARRAY and raw_offset.size() >= 2:
			target_position += Vector2(float(raw_offset[0]), float(raw_offset[1]))

	if duration <= 0.0:
		camera_2d.global_position = target_position
		camera_2d.zoom = Vector2(zoom_value, zoom_value)
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(camera_2d, "global_position", target_position, duration)
	tween.tween_property(camera_2d, "zoom", Vector2(zoom_value, zoom_value), duration)

	await tween.finished


func run_dialog(step: Dictionary) -> void:
	var speaker := str(step.get("speaker", ""))
	var text := str(step.get("text", ""))

	var camera_marker_id := str(step.get("camera_marker", ""))

	if camera_marker_id != "":
		var camera_step := {
			"marker": camera_marker_id,
			"zoom": float(step.get("zoom", default_camera_zoom)),
			"duration": float(step.get("camera_duration", camera_transition_time))
		}

		if step.has("camera_offset"):
			camera_step["camera_offset"] = step.get("camera_offset")

		await run_camera(camera_step)

	var speaker_body := get_actor_by_speaker(speaker)

	if speaker_body == null:
		push_error("dialog: ไม่พบ CharacterBody2D ของ speaker: " + speaker)
		return

	var listener_body := get_listener_for_speaker(speaker_body)

	if listener_body != null:
		face_position(speaker_body, listener_body.global_position)

	hide_all_dialogs()

	var bubble := get_dialog_bubble_by_actor(speaker_body)

	if bubble == null:
		push_error("dialog: ไม่พบ DialogBubble ของ speaker: " + speaker + " ให้ลาก bubble ใส่ Inspector โดยตรง")
		return

	if not bubble.has_method("start_dialog"):
		push_error("dialog: DialogBubble ไม่มี method start_dialog(speaker, lines)")
		return

	# Tria ไม่มี talk animation ให้ใช้ idle แทน
	# Wendy ยังใช้ talk ได้
	if speaker_body == tria_body:
		play_actor_animation(speaker_body, idle_animation)
	else:
		play_actor_animation(speaker_body, talk_animation)

	var one_line: Array[String] = [text]
	bubble.start_dialog(speaker, one_line)

	active_dialog_bubble = bubble
	active_speaker_body = speaker_body
	waiting_for_dialog_input = true

	while waiting_for_dialog_input:
		await get_tree().process_frame

	hide_dialog_bubble(bubble)
	play_actor_animation(speaker_body, idle_animation)


func advance_dialog_input() -> void:
	if active_dialog_bubble == null:
		waiting_for_dialog_input = false
		active_speaker_body = null
		return

	if not active_dialog_bubble.has_method("advance_or_finish_line"):
		waiting_for_dialog_input = false
		active_dialog_bubble = null
		active_speaker_body = null
		return

	var finished: bool = active_dialog_bubble.advance_or_finish_line()

	if finished:
		waiting_for_dialog_input = false
		active_dialog_bubble = null
		active_speaker_body = null


func run_wait(step: Dictionary) -> void:
	var duration := float(step.get("duration", 0.25))

	if duration <= 0.0:
		return

	await get_tree().create_timer(duration).timeout


func run_fade(step: Dictionary, fade_to_black: bool) -> void:
	if fade_rect == null:
		push_warning("fade_rect ยังไม่ได้ assign")
		return

	var duration := float(step.get("duration", 0.5))

	fade_rect.visible = true

	var start_alpha := 0.0
	var end_alpha := 1.0

	if not fade_to_black:
		start_alpha = 1.0
		end_alpha = 0.0

	fade_rect.color.a = start_alpha

	if duration <= 0.0:
		fade_rect.color.a = end_alpha
	else:
		var tween := create_tween()
		tween.tween_property(fade_rect, "color:a", end_alpha, duration)
		await tween.finished

	if not fade_to_black:
		fade_rect.visible = false


func run_change_scene() -> void:
	var next_scene := str(cutscene_data.get("next_scene", ""))

	if next_scene.is_empty():
		push_warning("ไม่มี next_scene ใน JSON")
		return

	get_tree().change_scene_to_file(next_scene)


func finish_cutscene_without_scene_change() -> void:
	hide_all_dialogs()

	unlock_actor(tria_body)
	unlock_actor(wendy_body)

	if fade_rect != null:
		fade_rect.visible = false

	waiting_for_dialog_input = false
	active_dialog_bubble = null
	active_speaker_body = null


func lock_actor(actor: CharacterBody2D) -> void:
	if actor == null:
		return

	saved_actor_states[actor] = {
		"physics": actor.is_physics_processing(),
		"process": actor.is_processing()
	}

	actor.velocity = Vector2.ZERO
	actor.set_physics_process(false)
	actor.set_process(actor.is_processing())


func unlock_actor(actor: CharacterBody2D) -> void:
	if actor == null:
		return

	actor.velocity = Vector2.ZERO

	if saved_actor_states.has(actor):
		var state: Dictionary = saved_actor_states[actor]
		actor.set_physics_process(bool(state.get("physics", true)))
		actor.set_process(bool(state.get("process", true)))
	else:
		actor.set_physics_process(true)


func teleport_actor(actor: CharacterBody2D, pos: Vector2) -> void:
	actor.global_position = pos
	actor.velocity = Vector2.ZERO


func hide_all_dialogs() -> void:
	hide_dialog_bubble(tria_dialog_bubble)
	hide_dialog_bubble(wendy_dialog_bubble)


func hide_dialog_bubble(bubble: Node) -> void:
	if bubble == null:
		return

	if bubble.has_method("hide_bubble"):
		bubble.hide_bubble()
	else:
		bubble.hide()


func get_actor_body(id: String) -> CharacterBody2D:
	match id:
		"tria", "player", "princess_tria", "Princess Tria", "Tria":
			return tria_body
		"wendy", "Wendy":
			return wendy_body
		_:
			return null


func get_actor_by_speaker(speaker: String) -> CharacterBody2D:
	match speaker:
		"Princess Tria", "Tria", "tria", "player", "princess_tria":
			return tria_body
		"Wendy", "wendy":
			return wendy_body
		_:
			return null


func get_listener_for_speaker(speaker_body: CharacterBody2D) -> CharacterBody2D:
	if speaker_body == tria_body:
		return wendy_body

	if speaker_body == wendy_body:
		return tria_body

	return null


func get_dialog_bubble_by_actor(actor: CharacterBody2D) -> Node:
	if actor == tria_body:
		return tria_dialog_bubble

	if actor == wendy_body:
		return wendy_dialog_bubble

	return null


func get_actor_sprite(actor: CharacterBody2D) -> AnimatedSprite2D:
	if actor == tria_body:
		return tria_sprite

	if actor == wendy_body:
		return wendy_sprite

	return null


func play_actor_animation(actor: CharacterBody2D, animation_name: StringName) -> void:
	if actor == null:
		return

	if animation_name == &"":
		return

	var sprite := get_actor_sprite(actor)

	if sprite == null:
		push_warning(actor.name + ": ยังไม่ได้ assign AnimatedSprite2D")
		return

	if sprite.sprite_frames == null:
		push_warning(actor.name + ": AnimatedSprite2D ไม่มี SpriteFrames")
		return

	if not sprite.sprite_frames.has_animation(animation_name):
		push_warning(actor.name + ": ไม่มี animation " + str(animation_name))
		return

	if sprite.animation != animation_name:
		sprite.play(animation_name)


func play_actor_animation_and_wait(actor: CharacterBody2D, animation_name: StringName, fallback_delay: float = 0.25) -> void:
	if actor == null:
		return

	var sprite := get_actor_sprite(actor)

	if sprite == null:
		await get_tree().create_timer(fallback_delay).timeout
		return

	if animation_name == &"":
		await get_tree().create_timer(fallback_delay).timeout
		return

	if sprite.sprite_frames == null:
		await get_tree().create_timer(fallback_delay).timeout
		return

	if not sprite.sprite_frames.has_animation(animation_name):
		await get_tree().create_timer(fallback_delay).timeout
		return

	sprite.play(animation_name)

	var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 1:
		await get_tree().create_timer(fallback_delay).timeout
		return

	await sprite.animation_finished


func face_position(actor: CharacterBody2D, target_position: Vector2) -> void:
	if actor == null:
		return

	var sprite := get_actor_sprite(actor)

	if sprite == null:
		return

	sprite.flip_h = target_position.x < actor.global_position.x


func set_actor_flip(actor: CharacterBody2D, flip_h: bool) -> void:
	var sprite := get_actor_sprite(actor)

	if sprite == null:
		return

	sprite.flip_h = flip_h


func get_marker(id: String) -> Node2D:
	match id:
		"tria_start":
			return tria_start
		"tria_talk_point":
			return tria_talk_point
		"wendy_point":
			return wendy_point
		"camera_wide":
			return camera_wide
		"camera_tria":
			return camera_tria
		"camera_wendy":
			return camera_wendy
		"camera_two_shot":
			return camera_two_shot
		_:
			return null
