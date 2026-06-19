extends Node2D

@export var interact_key: StringName = "ui_talk"

@export var required_item: String = "A2 key"
@export var required_amount: int = 1
@export var consume_key: bool = false

@export_file("*.tscn")
var next_scene_path: String = ""

@export var closed_animation: StringName = "closed"
@export var opening_animation: StringName = "opening"
@export var open_animation: StringName = "open"

# รอให้ผู้เล่นเห็นประตูเปิดก่อนเปลี่ยนซีน
@export var wait_after_open: float = 0.5

@onready var door_sprite: AnimatedSprite2D = $door
@onready var interact_area: Area2D = $Area2D
@onready var hint: Node = $hintE

var player_in_range: bool = false
var current_player: Node2D = null

var is_open: bool = false
var is_animating: bool = false


func _ready() -> void:
	call_hide_hint()

	if door_sprite != null:
		play_door_animation(closed_animation)

	if interact_area != null:
		if not interact_area.body_entered.is_connected(_on_body_entered):
			interact_area.body_entered.connect(_on_body_entered)

		if not interact_area.body_exited.is_connected(_on_body_exited):
			interact_area.body_exited.connect(_on_body_exited)
	else:
		push_error("A2Door ไม่มี Area2D สำหรับตรวจจับ player")


func _process(_delta: float) -> void:
	if not player_in_range:
		return

	if is_animating:
		return

	if Input.is_action_just_pressed(interact_key):
		interact()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		call_show_hint()


func _on_body_exited(body: Node2D) -> void:
	if body == current_player:
		player_in_range = false
		current_player = null
		call_hide_hint()


func interact() -> void:
	if is_animating:
		return

	if is_open:
		go_to_next_scene()
		return

	if not has_required_key():
		print("ประตูล็อกอยู่ ต้องใช้ ", required_item)
		return

	await open_door()

	await get_tree().create_timer(wait_after_open).timeout

	go_to_next_scene()


func open_door() -> void:
	if is_open:
		return

	is_animating = true
	call_hide_hint()

	if consume_key:
		spend_required_key()

	if door_sprite != null:
		# เล่นอนิเมชั่นกำลังเปิด ถ้ามี
		if has_animation(opening_animation):
			door_sprite.play(opening_animation)
			await door_sprite.animation_finished

		# ตั้งเป็นภาพประตูเปิดค้าง
		if has_animation(open_animation):
			door_sprite.play(open_animation)
			door_sprite.frame = 0
			door_sprite.pause()
		else:
			push_warning("ไม่มี animation open: " + str(open_animation))

	is_open = true
	is_animating = false


func go_to_next_scene() -> void:
	if next_scene_path.is_empty():
		push_error("A2Door: ยังไม่ได้ใส่ next_scene_path ใน Inspector")
		return

	get_tree().change_scene_to_file(next_scene_path)


func has_required_key() -> bool:
	if not is_instance_valid(BlessingManager):
		push_error("ไม่พบ BlessingManager Autoload")
		return false

	if not BlessingManager.has_method("has_item"):
		push_error("BlessingManager ไม่มี method has_item(item_id, amount)")
		return false

	return BlessingManager.has_item(required_item, required_amount)


func spend_required_key() -> bool:
	if not is_instance_valid(BlessingManager):
		push_error("ไม่พบ BlessingManager Autoload")
		return false

	if not BlessingManager.has_method("spend_item"):
		push_error("BlessingManager ไม่มี method spend_item(item_id, amount)")
		return false

	return BlessingManager.spend_item(required_item, required_amount)


func play_door_animation(animation_name: StringName) -> void:
	if door_sprite == null:
		return

	if door_sprite.sprite_frames == null:
		return

	if not door_sprite.sprite_frames.has_animation(animation_name):
		push_warning("DoorSprite ไม่มี animation: " + str(animation_name))
		return

	door_sprite.play(animation_name)


func has_animation(animation_name: StringName) -> bool:
	if door_sprite == null:
		return false

	if door_sprite.sprite_frames == null:
		return false

	return door_sprite.sprite_frames.has_animation(animation_name)


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
