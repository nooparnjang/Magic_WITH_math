extends Node2D


func _input(event: InputEvent) -> void:
	# ตรวจสอบว่าเป็นการคลิกเมาส์ซ้าย และเป็นการกดลงไป (Pressed)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		change_to_next_scene()

func change_to_next_scene() -> void:
	# ใส่ Path ของ Scene ถัดไปที่คุณต้องการเปลี่ยนไปหา 
	# ตัวอย่างเช่น ลากไฟล์จาก FileSystem มาวางในวงเล็บได้เลย
	get_tree().change_scene_to_file("res://UIcomponent/endcredit.tscn")
