extends Control

@export var bgm: AudioStreamPlayer

func _ready() -> void:
	play_transition_in()
	fade_music_up()

func play_transition_in() -> void:
	var anim_player: AnimationPlayer = $AnimationPlayer

	if anim_player == null:
		push_warning("หา AnimationPlayer ไม่เจอ")
		return

	if not anim_player.has_animation("transition"):
		push_warning("ไม่มี animation ชื่อ transition")
		return

	anim_player.play("transition")

func fade_music_up() -> void:
	if bgm == null:
		return

	# เริ่มจากเบาก่อน แล้วค่อยดังกลับ
	bgm.volume_db = -30.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bgm, "volume_db", -20.069, 1.0)
