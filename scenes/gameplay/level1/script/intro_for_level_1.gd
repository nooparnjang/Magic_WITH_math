extends Control

@export var next_button: Button
@export var next_scene: PackedScene

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# สำคัญมาก: กันกรณีซีนก่อนหน้ากด pause ค้างไว้
	get_tree().paused = false

	# ให้ UI / Animation ทำงานได้ชัวร์
	process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.process_mode = Node.PROCESS_MODE_ALWAYS

	# ซ่อนปุ่มก่อน
	if next_button != null:
		next_button.visible = false
		next_button.disabled = true

	# เช็กว่ามี animation ชื่อนี้จริงไหม
	if animation_player.has_animation("typing"):
		animation_player.play("typing")
	else:
		push_error("ไม่มี Animation ชื่อ typing ใน AnimationPlayer")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "typing":
		return

	if next_button != null:
		next_button.visible = true
		next_button.disabled = false


func _on_button_pressed() -> void:
	if next_scene == null:
		push_error("ยังไม่ได้ใส่ next_scene ใน Inspector")
		return

	get_tree().paused = false
	get_tree().change_scene_to_packed(next_scene)
