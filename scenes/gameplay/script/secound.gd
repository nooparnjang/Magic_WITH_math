extends Control

var played_once := false

func _on_area_body_entered(body: Node2D) -> void:
	if played_once:
		return
	
	if not body.is_in_group("player"):
		return  
	
	print("detect player")
	$AnimationPlayer.play("secondTextTut")
	played_once = true
