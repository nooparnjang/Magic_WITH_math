extends Node2D

@export var camera_rig: Node2D
@export var focus_target: StaticBody2D
@export var focus_duration := 1.2


var played_once := false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if played_once:
		return
	
	if not body.is_in_group("player"):
		return
	
	played_once = true
	
	await camera_rig.focus_on(focus_target, focus_duration)
