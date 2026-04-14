extends Node2D

@export var bgm: AudioStreamPlayer
@export var next_scene_path: PackedScene

var played_once := false

func _ready() -> void:
	$Area2D.body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("ชนกับ:", body.name)

	if played_once:
		return
	
	if not body.is_in_group("player"):
		return
	
	played_once = true

	fade_music_down()
	await change_scene_with_transition()

func change_scene_with_transition() -> void:
	var anim_player: AnimationPlayer = $TransitionLayer/AnimationPlayer
	anim_player.play("transition")

	var finished_anim: String = await anim_player.animation_finished

	if finished_anim == "transition":
		if next_scene_path == null:
			push_warning("ยังไม่ได้ assign next_scene_path ใน Inspector")
			return

		get_tree().change_scene_to_packed(next_scene_path)

func fade_music_down() -> void:
	if bgm == null:
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bgm, "volume_db", -30.0, 0.8)
