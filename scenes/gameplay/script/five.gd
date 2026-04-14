extends Node2D

@export var bgm: AudioStreamPlayer

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
	$TransitionLayer/AnimationPlayer.play("transition")

func fade_music_down() -> void:
	if bgm == null:
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bgm, "volume_db", -30.0, 0.8)
