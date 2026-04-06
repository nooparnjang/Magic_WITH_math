extends Control

var played_once := false

func _on_area_2d_body_entered(_body: Node2D) -> void:
	if played_once:
		return  # เคยเล่นแล้ว → ไม่ต้องทำอะไร

	print("detect")
	$AnimationPlayer.play("Third")
	played_once = true
