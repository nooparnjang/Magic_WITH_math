extends Node

signal cutscene_finished

@export_file("*.json")
var cutscene_json_path: String = "res://cutscenes/json/wendy_disappear_cutscene.json"

@export var auto_start: bool = true
@export var play_once: bool = true
@export var advance_action: StringName = &"ui_talk"

@export_group("Actors - CharacterBody2D")
@export var tria_body: CharacterBody2D
@export var wendy_body: CharacterBody2D

@export_group("Actor Sprites")
@export var tria_sprite: AnimatedSprite2D
@export var wendy_sprite: AnimatedSprite2D

@export_group("Sprite Facing")
@export var tria_faces_right_by_default: bool = true
@export var wendy_faces_right_by_default: bool = true

@export_group("Dialog Bubbles - Assign Directly")
@export var tria_dialog_bubble: Node
@export var wendy_dialog_bubble: Node

@export_group("Camera")
@export var camera_2d: Camera2D
@export var default_camera_zoom: float = 1.0
@export var camera_transition_time: float = 0.45

# ค่า y มากขึ้น = กล้องเลื่อนลงใน Godot 2D
@export var camera_two_shot_offset: Vector2 = Vector2(0, 45)

@export_group("Actor Markers")
# tria_start ไม่จำเป็นสำหรับคัตซีนนี้แล้ว
# เก็บไว้ได้ เผื่อคัตซีนอื่นอยาก teleport ตัวละคร
@export var tria_start: Node2D
@export var tria_talk_point: Node2D
@export var tria_run: Node2D
@export var wendy_point: Node2D

@export_group("Camera Markers")
@export var camera_wide: Node2D
@export var camera_tria: Node2D
@export var camera_wendy: Node2D
@export var camera_two_shot: Node2D

@export_group("Wendy Hide Targets")
# ใส่ node ที่อยากให้หายเพิ่ม เช่น object/Comwendy หรือ capsule ของ Wendy
@export var wendy_nodes_to_hide: Array[Node] = []

@export_group("Fade")
@export var fade_rect: ColorRect

@export_group("Animation Names")
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"walk"
@export var talk_animation: StringName = &"talk"

var cutscene_data: Dictionary = {}

var is_playing: bool = false
var has_played: bool = false
var wendy_disappeared: bool = false

var waiting_for_dialog_input: bool = false
var active_dialog_bubble: Node = null
var active_speaker_body: CharacterBody2D = null

var saved_actor_states: Dictionary = {}


func _ready() -> void:
	hide_all_dialogs()

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

	if play_once and has_played:
		return

	if path != "":
		cutscene_json_path = path

	is_playing = true
	has_played = true
	wendy_disappeared = false

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

		"hide_wendy":
			run_hide_wendy()

		"change_scene":
			run_change_scene()

		"finish":
			finish_cutscene_without_scene_change()

		_:
			push_warning("ไม่รู้จัก cutscene step type: " + step_type)


# ------------------------------------------------------------
# Actor setup / animation
# ------------------------------------------------------------

func run_setup_actor(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var marker_id := str(step.get("marker", ""))
	var animation_name := StringName(str(step.get("animation", "")))

	var actor := get_actor_body(actor_id)

	if actor == null:
		push_warning("setup_actor: ไม่พบ actor " + actor_id)
		return

	# ถ้า JSON ไม่มี marker หรือ marker เป็น "" จะไม่ย้ายตัวละคร
	# ดังนั้น Tria / Wendy จะอยู่ตรงที่วางไว้ในฉาก
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


# ------------------------------------------------------------
# Movement / Camera
# ------------------------------------------------------------

func run_move_actor(step: Dictionary) -> void:
	var actor_id := str(step.get("actor", ""))
	var marker_id := str(step.get("marker", ""))
	var duration := float(step.get("duration", 1.0))
	var animation_name := StringName(str(step.get("animation", str(walk_animation))))

	# x_only = true หมายถึง:
	# ใช้ X ของ marker แต่ใช้ Y เดิมของ actor
	# เหมาะกับ side-scroller ที่อยากให้ตัวละครวิ่งแนวนอนเท่านั้น
	var x_only := bool(step.get("x_only", false))

	var actor := get_actor_body(actor_id)
	var marker := get_marker(marker_id)

	if actor == null:
		push_warning("move_actor: ไม่พบ actor " + actor_id)
		return

	if marker == null:
		push_warning("move_actor: ไม่พบ marker " + marker_id)
		return

	var target_position := marker.global_position

	if x_only:
		target_position.y = actor.global_position.y

	face_position(actor, target_position)
	play_actor_animation(actor, animation_name)

	actor.velocity = Vector2.ZERO

	if duration <= 0.0:
		teleport_actor(actor, target_position)
		play_actor_animation(actor, idle_animation)
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(actor, "global_position", target_position, duration)

	await tween.finished

	actor.velocity = Vector2.ZERO
	play_actor_animation(actor, idle_animation)


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

	if marker_id == "camera_two_shot":
		target_position += camera_two_shot_offset

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


# ------------------------------------------------------------
# Dialog
# ------------------------------------------------------------

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

	if speaker_body == tria_body:
		play_actor_animation(speaker_body, idle_animation)
	else:
		play_actor_animation(speaker_body, talk_animation)

	var one_line: Array[String] = [text]
	bubble.call("start_dialog", speaker, one_line)

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

	var finished: bool = bool(active_dialog_bubble.call("advance_or_finish_line"))

	if finished:
		waiting_for_dialog_input = false
		active_dialog_bubble = null
		active_speaker_body = null


# ------------------------------------------------------------
# Wait / Fade / Hide
# ------------------------------------------------------------

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


func run_hide_wendy() -> void:
	wendy_disappeared = true

	hide_dialog_bubble(wendy_dialog_bubble)

	if wendy_body != null:
		wendy_body.velocity = Vector2.ZERO
		wendy_body.hide()
		wendy_body.set_physics_process(false)
		wendy_body.set_process(false)
		set_collision_disabled_recursive(wendy_body, true)

	for node in wendy_nodes_to_hide:
		if node == null:
			continue

		if node is CanvasItem:
			(node as CanvasItem).hide()

		set_collision_disabled_recursive(node, true)


func set_collision_disabled_recursive(root: Node, disabled: bool) -> void:
	if root == null:
		return

	for child in root.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", disabled)

		if child is CollisionPolygon2D:
			(child as CollisionPolygon2D).set_deferred("disabled", disabled)

		set_collision_disabled_recursive(child, disabled)


# ------------------------------------------------------------
# Finish / Scene
# ------------------------------------------------------------

func run_change_scene() -> void:
	var next_scene := str(cutscene_data.get("next_scene", ""))

	if next_scene.is_empty():
		push_warning("ไม่มี next_scene ใน JSON")
		return

	get_tree().change_scene_to_file(next_scene)


func finish_cutscene_without_scene_change() -> void:
	hide_all_dialogs()

	unlock_actor(tria_body)

	if not wendy_disappeared:
		unlock_actor(wendy_body)

	if fade_rect != null:
		fade_rect.visible = false
		fade_rect.color.a = 0.0

	waiting_for_dialog_input = false
	active_dialog_bubble = null
	active_speaker_body = null
	is_playing = false

	cutscene_finished.emit()


# ------------------------------------------------------------
# Lock / Unlock
# ------------------------------------------------------------

func lock_actor(actor: CharacterBody2D) -> void:
	if actor == null:
		return

	saved_actor_states[actor] = {
		"physics": actor.is_physics_processing(),
		"process": actor.is_processing()
	}

	actor.velocity = Vector2.ZERO
	actor.set_physics_process(false)


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
		actor.set_process(true)


func teleport_actor(actor: CharacterBody2D, pos: Vector2) -> void:
	if actor == null:
		return

	actor.global_position = pos
	actor.velocity = Vector2.ZERO


# ------------------------------------------------------------
# Dialog Bubble Helpers
# ------------------------------------------------------------

func hide_all_dialogs() -> void:
	hide_dialog_bubble(tria_dialog_bubble)
	hide_dialog_bubble(wendy_dialog_bubble)


func hide_dialog_bubble(bubble: Node) -> void:
	if bubble == null:
		return

	if bubble.has_method("hide_bubble"):
		bubble.call("hide_bubble")
		return

	if bubble is CanvasItem:
		(bubble as CanvasItem).hide()


# ------------------------------------------------------------
# Actor Helpers
# ------------------------------------------------------------

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


func get_faces_right_by_default(actor: CharacterBody2D) -> bool:
	if actor == tria_body:
		return tria_faces_right_by_default

	if actor == wendy_body:
		return wendy_faces_right_by_default

	return true


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
	else:
		if not sprite.is_playing():
			sprite.play()


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

	var target_is_left := target_position.x < actor.global_position.x
	var faces_right_by_default := get_faces_right_by_default(actor)

	if faces_right_by_default:
		sprite.flip_h = target_is_left
	else:
		sprite.flip_h = not target_is_left


func set_actor_flip(actor: CharacterBody2D, flip_h: bool) -> void:
	var sprite := get_actor_sprite(actor)

	if sprite == null:
		return

	sprite.flip_h = flip_h


func get_marker(id: String) -> Node2D:
	match id:
		"tria_start", "triaStart":
			return tria_start

		"tria_talk_point":
			return tria_talk_point

		"tria_run", "triarun":
			return tria_run

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
