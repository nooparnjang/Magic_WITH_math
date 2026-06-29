extends StaticBody2D


@export var stand_time: float = 3.0 # เวลาที่ต้องยืนก่อนหาย
@export var blink_duration: float = 1.0 # เวลากระพริบก่อนหาย
@export var respawn_time: float = 3.0
@export var blink_speed: float = 0.15


var player_on_block := false
var activated := false



func _on_area_2d_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):

		print("ผู้เล่นเหยียบ")

		player_on_block = true


		if activated:
			return


		activated = true

		start_sequence()



func _on_area_2d_body_exited(body: Node2D) -> void:

	if body.is_in_group("player"):

		print("ผู้เล่นออก")

		player_on_block = false



func start_sequence() -> void:


	# รอให้ผู้เล่นยืนครบ 3 วิ
	await get_tree().create_timer(stand_time).timeout



	# ถ้าออกก่อน 3 วิ หยุดทันที
	if not player_on_block:

		print("ออกก่อนครบเวลา ยกเลิก")

		activated = false

		return



	# ครบ 3 วิแล้ว ค่อยกระพริบ
	print("ครบ 3 วิ เริ่มเตือน")


	await blink_warning()



	# ถ้าออกตอนกระพริบ ไม่หาย
	if not player_on_block:

		print("ออกตอนเตือน ยกเลิก")

		$Sprite2D.show()

		activated = false

		return



	# หาย
	disappear()



	# รอ 3 วิ
	await get_tree().create_timer(respawn_time).timeout



	respawn()




func blink_warning() -> void:

	var time := 0.0


	while time < blink_duration:


		if not player_on_block:

			$Sprite2D.show()

			return



		$Sprite2D.hide()

		await get_tree().create_timer(blink_speed).timeout


		$Sprite2D.show()

		await get_tree().create_timer(blink_speed).timeout


		time += blink_speed * 2





func disappear() -> void:

	print("พื้นหาย")


	$CollisionShape2D.set_deferred("disabled", true)

	$Area2D/CollisionShape2D.set_deferred("disabled", true)

	$Sprite2D.hide()




func respawn() -> void:

	print("พื้นกลับมา")


	$CollisionShape2D.set_deferred("disabled", false)

	$Area2D/CollisionShape2D.set_deferred("disabled", false)

	$Sprite2D.show()


	activated = false
