extends Area2D

@export var camera_rig: Node2D
@export var dead_robot: Node2D
@export var dead_robot_mark: Marker2D
@export var alive_robot_scene: PackedScene

@export var focus_wait_before_animation := 0.5
@export var wait_before_camera_return := 0.4

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if triggered:
		return

	if not body.is_in_group("player"):
		return

	if dead_robot == null or not is_instance_valid(dead_robot):
		return

	triggered = true

	await wake_up_sequence()


func wake_up_sequence() -> void:
	# 1. โฟกัสกล้องไปที่ DeadRobot ไม่ใช่ Area2D
	if camera_rig != null and camera_rig.has_method("lock_focus"):
		camera_rig.lock_focus(dead_robot_mark)

	# 2. รอให้กล้องเลื่อนไปหา dead robot ก่อน
	await get_tree().create_timer(focus_wait_before_animation).timeout

	# 3. เล่น animation ฟื้น
	var sprite: AnimatedSprite2D = dead_robot.get_node_or_null("AnimatedSprite2D")

	if sprite == null:
		push_warning("DeadRobot ไม่มี AnimatedSprite2D")
		return

	sprite.play("default")

	await sprite.animation_finished

	# 4. Spawn หุ่นเดินได้ที่ตำแหน่ง dead robot
	spawn_alive_robot()

	# 5. ลบ dead robot
	if is_instance_valid(dead_robot):
		dead_robot.queue_free()

	# 6. รอก่อนคืนกล้องนิดหนึ่ง
	await get_tree().create_timer(wait_before_camera_return).timeout

	# 7. คืนกล้องกลับ player
	if camera_rig != null and camera_rig.has_method("unlock_focus"):
		camera_rig.unlock_focus()

	# 8. ปิด trigger ไม่ให้ทำงานซ้ำ
	queue_free()


func spawn_alive_robot() -> void:
	if alive_robot_scene == null:
		push_warning("ยังไม่ได้ใส่ alive_robot_scene")
		return

	var robot := alive_robot_scene.instantiate()
	get_tree().current_scene.add_child(robot)

	robot.global_position = dead_robot_mark.global_position
	robot.scale = Vector2(2.5, 2.5)
