extends Area2D

@export var camera_rig: Node2D
@export var focus_target: Node2D
@export var focus_duration := 1.6
@export var trigger_once := true

var played_once := false

func _on_body_entered(body: Node2D) -> void:
	if trigger_once and played_once:
		return

	if not body.is_in_group("player"):
		return

	played_once = true

	if camera_rig != null and camera_rig.has_method("focus_on") and focus_target != null:
		await camera_rig.focus_on(focus_target, focus_duration)
