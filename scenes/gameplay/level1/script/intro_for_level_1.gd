extends Control

@export var next_button: Button
@export var next_scene: PackedScene

func _ready() -> void:
	$AnimationPlayer.play("typing")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "typing":
		next_button.visible = true


func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(next_scene) # Replace with function body.
