extends Area2D

func _on_body_entered(body):
	if !body.is_in_group("robot_hai"):
		return

	for robot in get_tree().get_nodes_in_group("robot_hai"):
		var tween = create_tween()
		tween.tween_property(robot, "modulate:a", 0.0, 0.3)
		tween.tween_callback(robot.queue_free)
